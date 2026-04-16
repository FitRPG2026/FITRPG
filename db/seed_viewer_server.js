const http = require("http");
const fs = require("fs");
const path = require("path");
const { execFileSync, spawn } = require("child_process");

const CONFIG = {
  container: process.env.SEED_VIEWER_CONTAINER || "fitrpg-seed-viewer-db",
  postgresImage: process.env.SEED_VIEWER_POSTGRES_IMAGE || "postgres:16-alpine",
  dbName: process.env.SEED_VIEWER_DB || "fitrpg",
  dbUser: "postgres",
  dbPassword: process.env.SEED_VIEWER_DB_PASSWORD || "fitrpg",
  dbPort: process.env.SEED_VIEWER_DB_PORT || "54332",
  uiPort: Number(process.env.SEED_VIEWER_UI_PORT || 3107),
};

const dbDir = __dirname;
const repoRoot = path.resolve(dbDir, "..");

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    cwd: repoRoot,
    encoding: "utf8",
    stdio: options.stdio || ["ignore", "pipe", "pipe"],
    env: process.env,
  });
}

function docker(args, options = {}) {
  return run("docker", args, options);
}

function log(message) {
  process.stdout.write(`[seed-viewer] ${message}\n`);
}

function containerExists() {
  const output = docker(["ps", "-a", "--filter", `name=^/${CONFIG.container}$`, "--format", "{{.Names}}"]);
  return output.trim() === CONFIG.container;
}

function waitForPostgres() {
  for (let i = 0; i < 60; i += 1) {
    try {
      docker(["exec", CONFIG.container, "pg_isready", "-U", CONFIG.dbUser, "-d", "postgres"]);
      return;
    } catch {
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1000);
    }
  }

  throw new Error("Postgres did not become ready within 60 seconds.");
}

function psql(database, sql) {
  return docker([
    "exec",
    CONFIG.container,
    "psql",
    "-v",
    "ON_ERROR_STOP=1",
    "-U",
    CONFIG.dbUser,
    "-d",
    database,
    "-t",
    "-A",
    "-c",
    sql,
  ]);
}

function psqlFile(database, filePathInsideContainer) {
  docker([
    "exec",
    CONFIG.container,
    "psql",
    "-v",
    "ON_ERROR_STOP=1",
    "-U",
    CONFIG.dbUser,
    "-d",
    database,
    "-f",
    filePathInsideContainer,
  ], { stdio: ["ignore", "ignore", "pipe"] });
}

function recreateDatabase() {
  log(`Recreating Docker container ${CONFIG.container}...`);
  if (containerExists()) {
    docker(["rm", "-f", CONFIG.container], { stdio: ["ignore", "ignore", "pipe"] });
  }

  docker([
    "run",
    "--name",
    CONFIG.container,
    "-e",
    `POSTGRES_PASSWORD=${CONFIG.dbPassword}`,
    "-p",
    `${CONFIG.dbPort}:5432`,
    "-d",
    CONFIG.postgresImage,
  ]);

  waitForPostgres();

  log("Copying db folder into the container...");
  docker(["cp", dbDir, `${CONFIG.container}:/tmp/db`], { stdio: ["ignore", "ignore", "pipe"] });

  log("Applying migrations...");
  psqlFile("postgres", "/tmp/db/migrations/000_init.sql");

  const migrations = fs
    .readdirSync(path.join(dbDir, "migrations"))
    .filter((name) => name.endsWith(".sql") && name !== "000_init.sql")
    .sort();

  for (const migration of migrations) {
    psqlFile(CONFIG.dbName, `/tmp/db/migrations/${migration}`);
  }

  log("Applying seed data...");
  psqlFile(CONFIG.dbName, "/tmp/db/queries/seed_all.sql");
}

function jsonQuery(sql) {
  const wrapped = `COPY (${sql}) TO STDOUT`;
  const output = psql(CONFIG.dbName, wrapped).trim();
  return output ? JSON.parse(output) : null;
}

function listTables() {
  return jsonQuery(`
    SELECT COALESCE(jsonb_agg(row_data ORDER BY table_name), '[]'::jsonb)
    FROM (
      SELECT
        table_name,
        (
          SELECT COUNT(*)::int
          FROM pg_catalog.pg_class c
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = 'public'
            AND c.relname = t.table_name
        ) AS oid_check,
        (
          SELECT COUNT(*)::int
          FROM information_schema.columns c
          WHERE c.table_schema = 'public'
            AND c.table_name = t.table_name
        ) AS column_count,
        (
          SELECT reltuples::bigint
          FROM pg_class
          WHERE oid = format('public.%I', t.table_name)::regclass
        ) AS estimated_rows
      FROM information_schema.tables t
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
    ) source
    CROSS JOIN LATERAL (
      SELECT jsonb_build_object(
        'table_name', source.table_name,
        'column_count', source.column_count,
        'estimated_rows', source.estimated_rows
      ) AS row_data
    ) payload
  `);
}

function tableCounts() {
  return jsonQuery(`
    SELECT COALESCE(jsonb_agg(jsonb_build_object('table_name', table_name, 'row_count', row_count) ORDER BY table_name), '[]'::jsonb)
    FROM (
      SELECT 'achievements' AS table_name, COUNT(*)::int AS row_count FROM achievements
      UNION ALL SELECT 'challenges', COUNT(*)::int FROM challenges
      UNION ALL SELECT 'exp_events', COUNT(*)::int FROM exp_events
      UNION ALL SELECT 'gym_workout_exercises', COUNT(*)::int FROM gym_workout_exercises
      UNION ALL SELECT 'meals', COUNT(*)::int FROM meals
      UNION ALL SELECT 'quests', COUNT(*)::int FROM quests
      UNION ALL SELECT 'user_achievements', COUNT(*)::int FROM user_achievements
      UNION ALL SELECT 'user_auth', COUNT(*)::int FROM user_auth
      UNION ALL SELECT 'user_challenges', COUNT(*)::int FROM user_challenges
      UNION ALL SELECT 'user_profiles', COUNT(*)::int FROM user_profiles
      UNION ALL SELECT 'user_progress', COUNT(*)::int FROM user_progress
      UNION ALL SELECT 'user_quests', COUNT(*)::int FROM user_quests
      UNION ALL SELECT 'users', COUNT(*)::int FROM users
      UNION ALL SELECT 'workouts', COUNT(*)::int FROM workouts
    ) counts
  `);
}

function assertTableName(tableName) {
  if (!/^[a-z_][a-z0-9_]*$/.test(tableName)) {
    throw new Error("Invalid table name.");
  }

  const exists = psql(CONFIG.dbName, `
    SELECT EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = '${tableName.replace(/'/g, "''")}'
    );
  `).trim();

  if (exists !== "t") {
    throw new Error(`Unknown table: ${tableName}`);
  }
}

function tableRows(tableName, limit = 100) {
  assertTableName(tableName);
  const safeLimit = Math.max(1, Math.min(Number(limit) || 100, 500));

  return jsonQuery(`
    SELECT COALESCE(jsonb_agg(to_jsonb(rows)), '[]'::jsonb)
    FROM (
      SELECT *
      FROM public.${tableName}
      ORDER BY 1
      LIMIT ${safeLimit}
    ) rows
  `);
}

function tableSchema(tableName) {
  assertTableName(tableName);
  const escaped = tableName.replace(/'/g, "''");

  return {
    columns: jsonQuery(`
      SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY ordinal_position), '[]'::jsonb)
      FROM (
        SELECT
          ordinal_position,
          column_name,
          data_type,
          udt_name,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = '${escaped}'
      ) c
    `),
    constraints: jsonQuery(`
      SELECT COALESCE(jsonb_agg(jsonb_build_object('name', conname, 'type', contype, 'definition', pg_get_constraintdef(oid)) ORDER BY conname), '[]'::jsonb)
      FROM pg_constraint
      WHERE conrelid = format('public.%I', '${escaped}')::regclass
    `),
    indexes: jsonQuery(`
      SELECT COALESCE(jsonb_agg(jsonb_build_object('name', indexname, 'definition', indexdef) ORDER BY indexname), '[]'::jsonb)
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename = '${escaped}'
    `),
  };
}

function queryJsonForDashboard() {
  return {
    tables: listTables(),
    counts: tableCounts(),
    workoutBreakdown: jsonQuery(`
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY activity_category), '[]'::jsonb)
      FROM (
        SELECT
          activity_category,
          COUNT(DISTINCT w.id)::int AS workouts,
          COUNT(gwe.id)::int AS exercise_rows
        FROM workouts w
        LEFT JOIN gym_workout_exercises gwe ON gwe.workout_id = w.id
        GROUP BY activity_category
      ) x
    `),
    missingLegacyTables: jsonQuery(`
      SELECT jsonb_build_object(
        'meal_items', to_regclass('public.meal_items') IS NOT NULL,
        'workout_exercises', to_regclass('public.workout_exercises') IS NOT NULL,
        'gym_workout_exercises', to_regclass('public.gym_workout_exercises') IS NOT NULL
      )
    `),
  };
}

function html() {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>FITRPG Seed Viewer</title>
  <style>
    :root {
      color-scheme: light;
      --ink: #18211f;
      --muted: #5d6a66;
      --line: #d7dfdc;
      --panel: #ffffff;
      --soft: #eff5f3;
      --accent: #1f7a5c;
      --accent-2: #b7354a;
      --focus: #0d5e88;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--ink);
      background: #f7faf9;
    }
    header {
      padding: 20px 24px;
      background: #13251f;
      color: #f7fbf9;
      border-bottom: 4px solid #1f7a5c;
    }
    h1 {
      margin: 0 0 6px;
      font-size: 24px;
      line-height: 1.2;
      letter-spacing: 0;
    }
    header p {
      margin: 0;
      color: #c7d8d2;
      font-size: 14px;
    }
    main {
      display: grid;
      grid-template-columns: 290px minmax(0, 1fr);
      gap: 18px;
      padding: 18px;
      max-width: 1500px;
      margin: 0 auto;
    }
    aside, section {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
    }
    aside {
      padding: 12px;
      align-self: start;
      position: sticky;
      top: 12px;
      max-height: calc(100vh - 24px);
      overflow: auto;
    }
    .summary {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 10px;
      margin-bottom: 18px;
    }
    .metric {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 12px;
      min-height: 76px;
    }
    .metric strong {
      display: block;
      font-size: 24px;
      line-height: 1.1;
    }
    .metric span {
      color: var(--muted);
      font-size: 13px;
    }
    .content {
      min-width: 0;
    }
    .panel {
      padding: 14px;
      margin-bottom: 18px;
      overflow: hidden;
    }
    .panel h2, aside h2 {
      margin: 0 0 10px;
      font-size: 16px;
      line-height: 1.3;
    }
    .table-list {
      display: grid;
      gap: 6px;
    }
    button {
      appearance: none;
      border: 1px solid var(--line);
      background: #fff;
      border-radius: 8px;
      color: var(--ink);
      cursor: pointer;
      font: inherit;
    }
    .table-button {
      display: grid;
      grid-template-columns: 1fr auto;
      gap: 8px;
      align-items: center;
      width: 100%;
      padding: 9px 10px;
      text-align: left;
    }
    .table-button.active {
      border-color: var(--accent);
      background: #e5f3ee;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      min-width: 32px;
      justify-content: center;
      border-radius: 8px;
      padding: 2px 7px;
      background: var(--soft);
      color: var(--muted);
      font-size: 12px;
    }
    .toolbar {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 10px;
    }
    .toolbar input {
      width: min(100%, 360px);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 9px 10px;
      font: inherit;
    }
    .tabs {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }
    .tabs button {
      padding: 8px 10px;
    }
    .tabs button.active {
      background: var(--accent);
      border-color: var(--accent);
      color: white;
    }
    .scroll {
      overflow: auto;
      border: 1px solid var(--line);
      border-radius: 8px;
      max-height: 62vh;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
      min-width: 760px;
    }
    th, td {
      border-bottom: 1px solid var(--line);
      padding: 8px 10px;
      text-align: left;
      vertical-align: top;
      white-space: nowrap;
    }
    th {
      position: sticky;
      top: 0;
      background: #edf4f1;
      z-index: 1;
    }
    td {
      max-width: 380px;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    pre {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      font-size: 12px;
      line-height: 1.45;
    }
    .status {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .pill {
      border: 1px solid var(--line);
      background: var(--soft);
      border-radius: 8px;
      padding: 7px 9px;
      font-size: 13px;
    }
    .ok { color: var(--accent); }
    .bad { color: var(--accent-2); }
    .muted { color: var(--muted); }
    @media (max-width: 860px) {
      main { grid-template-columns: 1fr; padding: 12px; }
      aside { position: static; max-height: none; }
      .summary { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }
  </style>
</head>
<body>
  <header>
    <h1>FITRPG Seed Viewer</h1>
    <p>Local seeded PostgreSQL preview from Docker container ${CONFIG.container} on port ${CONFIG.dbPort}.</p>
  </header>
  <main>
    <aside>
      <h2>Tables</h2>
      <div id="tables" class="table-list"></div>
    </aside>
    <div class="content">
      <div id="summary" class="summary"></div>
      <section class="panel">
        <h2>Workout split</h2>
        <div id="workoutBreakdown" class="status"></div>
      </section>
      <section class="panel">
        <div class="toolbar">
          <h2 id="selectedTitle">Select a table</h2>
          <input id="filter" placeholder="Filter visible rows">
        </div>
        <div class="tabs">
          <button id="rowsTab" class="active">Rows</button>
          <button id="schemaTab">Schema</button>
          <button id="jsonTab">JSON</button>
        </div>
        <div id="tableView" style="margin-top: 10px;"></div>
      </section>
    </div>
  </main>
  <script>
    const state = {
      dashboard: null,
      table: null,
      rows: [],
      schema: null,
      tab: "rows",
      filter: ""
    };

    async function getJson(url) {
      const response = await fetch(url);
      if (!response.ok) throw new Error(await response.text());
      return response.json();
    }

    function escapeHtml(value) {
      return String(value ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;");
    }

    function formatValue(value) {
      if (value === null || value === undefined) return "";
      if (typeof value === "object") return JSON.stringify(value);
      return String(value);
    }

    function renderDashboard() {
      const counts = state.dashboard.counts;
      const byName = Object.fromEntries(counts.map((item) => [item.table_name, item.row_count]));
      const legacy = state.dashboard.missingLegacyTables;
      document.getElementById("summary").innerHTML = [
        ["Users", byName.users],
        ["Meals", byName.meals],
        ["Workouts", byName.workouts],
        ["Gym exercises", byName.gym_workout_exercises]
      ].map(([label, value]) => '<div class="metric"><strong>' + value + '</strong><span>' + label + '</span></div>').join("");

      document.getElementById("workoutBreakdown").innerHTML =
        state.dashboard.workoutBreakdown.map((item) =>
          '<span class="pill"><strong>' + escapeHtml(item.activity_category) + '</strong>: ' +
          item.workouts + ' workouts, ' + item.exercise_rows + ' exercise rows</span>'
        ).join("") +
        '<span class="pill ' + (legacy.meal_items ? 'bad' : 'ok') + '">meal_items: ' + (legacy.meal_items ? 'exists' : 'missing as expected') + '</span>' +
        '<span class="pill ' + (legacy.workout_exercises ? 'bad' : 'ok') + '">workout_exercises: ' + (legacy.workout_exercises ? 'exists' : 'missing as expected') + '</span>' +
        '<span class="pill ' + (legacy.gym_workout_exercises ? 'ok' : 'bad') + '">gym_workout_exercises: ' + (legacy.gym_workout_exercises ? 'exists' : 'missing') + '</span>';

      document.getElementById("tables").innerHTML = counts.map((item) =>
        '<button class="table-button' + (state.table === item.table_name ? ' active' : '') + '" data-table="' + item.table_name + '">' +
        '<span>' + item.table_name + '</span><span class="badge">' + item.row_count + '</span></button>'
      ).join("");

      document.querySelectorAll("[data-table]").forEach((button) => {
        button.addEventListener("click", () => selectTable(button.dataset.table));
      });
    }

    function filteredRows() {
      const term = state.filter.trim().toLowerCase();
      if (!term) return state.rows;
      return state.rows.filter((row) => JSON.stringify(row).toLowerCase().includes(term));
    }

    function renderRows() {
      const rows = filteredRows();
      if (!rows.length) {
        return '<p class="muted">No rows match the current filter.</p>';
      }
      const columns = Array.from(rows.reduce((set, row) => {
        Object.keys(row).forEach((key) => set.add(key));
        return set;
      }, new Set()));
      return '<div class="scroll"><table><thead><tr>' +
        columns.map((column) => '<th>' + escapeHtml(column) + '</th>').join("") +
        '</tr></thead><tbody>' +
        rows.map((row) => '<tr>' + columns.map((column) => '<td title="' + escapeHtml(formatValue(row[column])) + '">' + escapeHtml(formatValue(row[column])) + '</td>').join("") + '</tr>').join("") +
        '</tbody></table></div>';
    }

    function renderSchema() {
      if (!state.schema) return "";
      return '<h3>Columns</h3>' + renderArrayTable(state.schema.columns) +
        '<h3>Constraints</h3>' + renderArrayTable(state.schema.constraints) +
        '<h3>Indexes</h3>' + renderArrayTable(state.schema.indexes);
    }

    function renderArrayTable(items) {
      if (!items || !items.length) return '<p class="muted">None.</p>';
      const columns = Array.from(items.reduce((set, row) => {
        Object.keys(row).forEach((key) => set.add(key));
        return set;
      }, new Set()));
      return '<div class="scroll" style="max-height: 320px;"><table><thead><tr>' +
        columns.map((column) => '<th>' + escapeHtml(column) + '</th>').join("") +
        '</tr></thead><tbody>' +
        items.map((row) => '<tr>' + columns.map((column) => '<td>' + escapeHtml(formatValue(row[column])) + '</td>').join("") + '</tr>').join("") +
        '</tbody></table></div>';
    }

    function renderTableView() {
      document.getElementById("rowsTab").classList.toggle("active", state.tab === "rows");
      document.getElementById("schemaTab").classList.toggle("active", state.tab === "schema");
      document.getElementById("jsonTab").classList.toggle("active", state.tab === "json");
      document.getElementById("selectedTitle").textContent = state.table ? state.table : "Select a table";
      renderDashboard();
      const view = document.getElementById("tableView");
      if (!state.table) {
        view.innerHTML = '<p class="muted">Pick a table from the left.</p>';
        return;
      }
      if (state.tab === "rows") view.innerHTML = renderRows();
      if (state.tab === "schema") view.innerHTML = renderSchema();
      if (state.tab === "json") view.innerHTML = '<div class="scroll"><pre>' + escapeHtml(JSON.stringify(state.rows, null, 2)) + '</pre></div>';
    }

    async function selectTable(tableName) {
      state.table = tableName;
      state.rows = await getJson('/api/table/' + tableName);
      state.schema = await getJson('/api/schema/' + tableName);
      renderTableView();
    }

    async function boot() {
      state.dashboard = await getJson('/api/dashboard');
      renderDashboard();
      const firstTable = state.dashboard.counts.find((item) => item.table_name === "challenges") || state.dashboard.counts[0];
      if (firstTable) await selectTable(firstTable.table_name);
    }

    document.getElementById("rowsTab").addEventListener("click", () => { state.tab = "rows"; renderTableView(); });
    document.getElementById("schemaTab").addEventListener("click", () => { state.tab = "schema"; renderTableView(); });
    document.getElementById("jsonTab").addEventListener("click", () => { state.tab = "json"; renderTableView(); });
    document.getElementById("filter").addEventListener("input", (event) => { state.filter = event.target.value; renderTableView(); });

    boot().catch((error) => {
      document.body.innerHTML = '<main><section class="panel"><h1>Seed viewer failed</h1><pre>' + escapeHtml(error.stack || error.message) + '</pre></section></main>';
    });
  </script>
</body>
</html>`;
}

function sendJson(response, payload) {
  response.writeHead(200, { "content-type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload));
}

function sendError(response, error) {
  response.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
  response.end(error.stack || String(error));
}

function startServer() {
  const server = http.createServer((request, response) => {
    try {
      const url = new URL(request.url, `http://localhost:${CONFIG.uiPort}`);
      if (url.pathname === "/") {
        response.writeHead(200, { "content-type": "text/html; charset=utf-8" });
        response.end(html());
        return;
      }
      if (url.pathname === "/api/dashboard") {
        sendJson(response, queryJsonForDashboard());
        return;
      }
      if (url.pathname.startsWith("/api/table/")) {
        sendJson(response, tableRows(decodeURIComponent(url.pathname.replace("/api/table/", "")), url.searchParams.get("limit") || 100));
        return;
      }
      if (url.pathname.startsWith("/api/schema/")) {
        sendJson(response, tableSchema(decodeURIComponent(url.pathname.replace("/api/schema/", ""))));
        return;
      }
      response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      response.end("Not found");
    } catch (error) {
      sendError(response, error);
    }
  });

  server.listen(CONFIG.uiPort, () => {
    const url = `http://localhost:${CONFIG.uiPort}`;
    log(`Seed viewer is running at ${url}`);
    if (process.env.SEED_VIEWER_NO_OPEN !== "1") {
      openBrowser(url);
    }
  });
}

function openBrowser(url) {
  if (process.platform === "win32") {
    spawn("cmd", ["/c", "start", "", url], { detached: true, stdio: "ignore" }).unref();
    return;
  }
  if (process.platform === "darwin") {
    spawn("open", [url], { detached: true, stdio: "ignore" }).unref();
    return;
  }
  spawn("xdg-open", [url], { detached: true, stdio: "ignore" }).unref();
}

function main() {
  try {
    recreateDatabase();
    startServer();
  } catch (error) {
    console.error(error.stack || error.message);
    process.exit(1);
  }
}

main();
