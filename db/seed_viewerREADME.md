# Seed Viewer

Local UI for checking the seeded PostgreSQL database without opening pgAdmin.

## What It Does

Running the viewer:

1. Recreates a local Docker PostgreSQL container.
2. Creates the `fitrpg` database.
3. Applies all SQL files from `db/migrations/` in filename order.
4. Runs `db/queries/seed_all.sql`.
5. Starts a small local web UI.
6. Opens the UI in your browser.

The tool is only for local development and database review.

## Requirements

- Docker Desktop running.
- Node.js available in terminal.
- Run the command from the repository root.

## Start

```powershell
node db\seed_viewer_server.js
```

Default URLs and ports:

```text
UI:       http://localhost:3107
Postgres: localhost:54332
DB:       fitrpg
User:     postgres
Password: fitrpg
Container: fitrpg-seed-viewer-db
```

Every run recreates the `fitrpg-seed-viewer-db` container, so the data is reset to the current migrations and seeds.

## UI

The UI lets you inspect:

- table row counts
- all seeded table rows
- table columns
- constraints
- indexes
- workout split by `activity_category`
- whether removed legacy tables are still absent

Expected seed checks:

```text
meal_items: missing as expected
workout_exercises: missing as expected
gym_workout_exercises: exists
```

Expected workout split:

```text
general: 5 workouts, 0 exercise rows
gym:     3 workouts, 11 exercise rows
sport:   2 workouts, 0 exercise rows
```

## Options

You can override ports or names with environment variables.

```powershell
$env:SEED_VIEWER_UI_PORT = "3110"
$env:SEED_VIEWER_DB_PORT = "54333"
$env:SEED_VIEWER_CONTAINER = "fitrpg-seed-viewer-test"
node db\seed_viewer_server.js
```

Disable automatic browser opening:

```powershell
$env:SEED_VIEWER_NO_OPEN = "1"
node db\seed_viewer_server.js
```

## Stop

Stop the UI process with `Ctrl+C` in the terminal where it is running.

Remove the database container:

```powershell
docker rm -f fitrpg-seed-viewer-db
```

If the UI was started in the background and port `3107` is still busy:

```powershell
Get-NetTCPConnection -LocalPort 3107 |
    Select-Object -ExpandProperty OwningProcess |
    Sort-Object -Unique |
    ForEach-Object { Stop-Process -Id $_ }
```

## Troubleshooting

If Docker is not running, start Docker Desktop and rerun the command.

If port `3107` is busy, set another UI port:

```powershell
$env:SEED_VIEWER_UI_PORT = "3110"
node db\seed_viewer_server.js
```

If port `54332` is busy, set another Postgres port:

```powershell
$env:SEED_VIEWER_DB_PORT = "54333"
node db\seed_viewer_server.js
```

If migrations or seeds fail, the script stops and prints the failing command output. Fix the SQL, then rerun the command.
