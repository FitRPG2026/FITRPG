import { test as setup, expect } from '@playwright/test';

const authFile = '.auth/user.json';

setup('Globalna autoryzacja w chmurze Vercel', async ({ page }) => {
  await page.goto('/login');
  
  await page.locator('input[type="email"]').fill('test_globalny@example.com');
  await page.locator('input[type="password"]').fill('Test123!');
  await page.getByRole('button', { name: /zaloguj się/i }).click();

  await expect(page).toHaveURL(/dashboard/);

  await expect(page.getByRole('heading', { name: /witaj z powrotem/i })).toBeVisible({ timeout: 10000 });

  await page.context().storageState({ path: authFile });
});