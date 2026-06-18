import { test, expect } from '@playwright/test';

test.describe('Zarządzanie treningami i profilem (Zalogowany użytkownik)', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page.getByRole('heading', { name: /witaj z powrotem/i }))
      .toBeVisible({ timeout: 30_000 });
  });

  test('B1: Dodawanie nowego treningu - sukces', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');

    await wf.getByPlaceholder('np. Klatka piersiowa').fill('Trening testowy');
    await wf.locator('select.form-select').selectOption('general'); // ukrywa tabelę ćwiczeń
    await wf.locator('input[type="number"]').first().fill('30');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();

    await expect(wf.getByText(/trening zapisany/i)).toBeVisible({ timeout: 15_000 });
  });

  test('B2: Pusty tytuł -> błąd walidacji', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');

    await wf.locator('select.form-select').selectOption('general');
    await wf.locator('input[type="number"]').first().fill('30');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();

    await expect(wf.getByText(/podaj nazwę treningu/i)).toBeVisible();
  });

  test('B3: Nieprawidłowy czas trwania -> błąd walidacji', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');

    await wf.getByPlaceholder('np. Klatka piersiowa').fill('Trening testowy');
    await wf.locator('select.form-select').selectOption('general');
    await wf.locator('input[type="number"]').first().fill('0');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();

    await expect(wf.getByText(/czas trwania musi być większy od 0/i)).toBeVisible();
  });

  // --- POMINIĘTE: oczekiwany tekst/zachowanie niezweryfikowane w realnej aplikacji ---
  test.skip('A3: Wejście do profilu po logowaniu', async () => {});
  test.skip('A4: Poprawność danych w profilu', async () => {});
  test.skip('B4: Trening z notatkami (zależne od listy historii)', async () => {});
  test.skip('B5: Trening typu Cardio (zależne od listy historii)', async () => {});
  test.skip('C1: Przyrost XP po dodaniu treningu', async () => {});
  test.skip('D1: Bardzo długi tytuł', async () => {});
  test.skip('D2: Minimalny czas trwania', async () => {});
});

// --- TEST BEZ AUTORYZACJI ---
test.describe('Niezalogowany użytkownik / Błędy autoryzacji', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('A2 / C2: Logowanie z niepoprawnymi danymi -> brak dostępu', async ({ page }) => {
    await page.goto('/login');
    await expect(page.locator('input[type="email"]')).toBeVisible({ timeout: 90_000 });

    await page.locator('input[type="email"]').fill('test_nieistniejace@example.com');
    await page.locator('input[type="password"]').fill('Test123!');
    await page.getByRole('button', { name: /zaloguj się/i }).click();

    // Niepoprawne dane NIE mogą dać dostępu do panelu.
    await page.waitForTimeout(3000);
    await expect(page).not.toHaveURL(/dashboard/);
    await expect(page.locator('input[type="email"]')).toBeVisible();
  });
});