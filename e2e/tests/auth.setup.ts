import { test as setup, expect } from '@playwright/test';

const authFile = '.auth/user.json';

setup('Globalna autoryzacja w chmurze Vercel', async ({ page }) => {
  // Backend (Render free tier) cold-starts; the splash screen blocks the
  // login form until /api/health responds. Allow time for that warm-up.
  setup.setTimeout(120_000);

  await page.goto('/login');

  const emailInput = page.locator('input[type="email"]');
  await emailInput.waitFor({ state: 'visible', timeout: 90_000 });

  await emailInput.fill('test_globalny@example.com');
  await page.locator('input[type="password"]').fill('Test123!');
  await page.getByRole('button', { name: /zaloguj się/i }).click();

  await expect(page).toHaveURL(/dashboard/, { timeout: 30_000 });
  await expect(page.getByRole('heading', { name: /witaj z powrotem/i }))
    .toBeVisible({ timeout: 15_000 });

  await page.context().storageState({ path: authFile });
});