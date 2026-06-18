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

  test('A3: Wejście do profilu po logowaniu', async ({ page }) => {
    await page.getByRole('button', { name: /profil/i }).click();
    await expect(page.getByRole('heading', { name: /profil/i })).toBeVisible();
    await expect(page.getByText(/poziom/i).first()).toBeVisible();
    await expect(page.getByText(/xp łącznie/i)).toBeVisible();
  });

  test('A4: Sprawdzenie poprawności danych w profilu', async ({ page }) => {
    await page.getByRole('button', { name: /profil/i }).click();
    await expect(page.getByText(/poziom\s*\d+/i).first()).toBeVisible();
    await expect(page.getByText(/xp łącznie/i)).toBeVisible();
  });

  test('B4: Trening z notatkami pojawia się w historii', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');
    const tytul = 'Notatki ' + Date.now();
    await wf.getByPlaceholder('np. Klatka piersiowa').fill(tytul);
    await wf.locator('select.form-select').selectOption('general');
    await wf.locator('input[type="number"]').first().fill('45');
    await wf.getByPlaceholder('Jak minął trening?').fill('Test notatki');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();
    await expect(wf.getByText(/trening zapisany/i)).toBeVisible({ timeout: 15_000 });
    await expect(page.locator('app-progress').getByText(tytul)).toBeVisible({ timeout: 15_000 });
  });

  test('B5: Trening typu Cardio pojawia się w historii', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');
    const tytul = 'Cardio ' + Date.now();
    await wf.getByPlaceholder('np. Klatka piersiowa').fill(tytul);
    await wf.locator('select.form-select').selectOption('cardio');
    await wf.locator('input[type="number"]').first().fill('60');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();
    await expect(wf.getByText(/trening zapisany/i)).toBeVisible({ timeout: 15_000 });
    await expect(page.locator('app-progress').getByText(tytul)).toBeVisible({ timeout: 15_000 });
  });

  test('D1: Dodawanie treningu z bardzo długim tytułem', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');
    await wf.getByPlaceholder('np. Klatka piersiowa').fill('A'.repeat(200));
    await wf.locator('select.form-select').selectOption('general');
    await wf.locator('input[type="number"]').first().fill('30');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();
    await expect(wf.getByText(/trening zapisany/i)).toBeVisible({ timeout: 15_000 });
  });

  test('D2: Dodawanie treningu z minimalnym czasem trwania', async ({ page }) => {
    await page.getByRole('button', { name: /trening/i }).click();
    const wf = page.locator('app-workout-form');
    await wf.getByPlaceholder('np. Klatka piersiowa').fill('Trening 1 minuta');
    await wf.locator('select.form-select').selectOption('general');
    await wf.locator('input[type="number"]').first().fill('1');
    await wf.getByRole('button', { name: /zapisz trening/i }).click();
    await expect(wf.getByText(/trening zapisany/i)).toBeVisible({ timeout: 15_000 });
  });

  // --- POMINIĘTE: oczekiwany tekst/zachowanie niezweryfikowane w realnej aplikacji ---
  test.skip('C1: Przyrost XP po dodaniu treningu', async () => {});
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