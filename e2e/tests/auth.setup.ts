import { test as setup, expect } from '@playwright/test';

const authFile = '.auth/user.json';
const backendUrl = 'http://localhost:8000';

setup('rejestracja i autoryzacja globalna', async ({ page }) => {
  const globalEmail = 'test_globalny@example.com';
  const globalPassword = 'Test123!';

  await page.request.post(`${backendUrl}/api/register`, {
    data: { email: globalEmail, password: globalPassword },
  }).catch(() => {});

  await page.goto('/', { waitUntil: 'networkidle' });
  
  await page.getByPlaceholder(/email/i).fill(globalEmail);
  await page.getByPlaceholder(/hasło/i).fill(globalPassword);
  await page.getByRole('button', { name: /zaloguj się/i }).click();

  await expect(page).toHaveURL(/dashboard/);

  await page.context().storageState({ path: authFile });
});