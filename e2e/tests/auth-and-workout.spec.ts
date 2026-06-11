import { test, expect } from '@playwright/test';

test.describe('Zarządzanie treningami i profilem (Zalogowany użytkownik)', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
  });

  // --- GRUPA A: PROFIL ---

  test('A3: Wejście do profilu po logowaniu', async ({ page }) => {
    await page.getByRole('link', { name: /^profil$/i }).click();

    await expect(page.getByText(/poziom/i)).toBeVisible();
    await expect(page.getByText(/xp/i)).toBeVisible();
    await expect(page.getByText(/questy/i)).toBeVisible();
    await expect(page.getByText(/osiągnięcia/i)).toBeVisible();
    await expect(page.getByText(/trening/i)).toBeVisible();
  });

  test('A4: Sprawdzenie poprawności danych w profilu', async ({ page }) => {
    await page.getByRole('link', { name: /^profil$/i }).click();

    const levelElement = page.getByText(/poziom [0-9]+/i);
    await expect(levelElement).toBeVisible();

    const xpProgress = page.getByText(/xp [0-9]+/i);
    await expect(xpProgress).toBeVisible();

    const statsSection = page.getByText(/statystyki/i);
    await expect(statsSection).toBeVisible();
  });

  // --- GRUPA B: SZYBKIE SCENARIUSZE FORMULARZA ---

  test('B1: Dodawanie nowego treningu - sukces', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();

    await page.getByPlaceholder(/tytuł treningu/i).fill('Trening testowy');
    await page.getByPlaceholder(/czas trwania/i).fill('30');
    await page.locator('select[name="type"]').selectOption('Cardio');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/trening zapisany/i)).toBeVisible();
    await expect(page.getByText(/punkty dodane/i)).toBeVisible();
    await expect(page.getByText(/trening testowy/i)).toBeVisible();
  });

  test('B2: Dodawanie treningu z pustym tytułem -> błąd walidacji', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();

    await page.getByPlaceholder(/czas trwania/i).fill('30');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/tytuł treningu jest wymagany/i)).toBeVisible();
    await expect(page.getByText(/nie można pominąć tego pola/i)).toBeVisible();
    await expect(page.getByText(/trening testowy/i)).not.toBeVisible();
  });

  test('B3: Dodawanie treningu z nieprawidłowym czasem trwania -> błąd walidacji', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();
    await page.getByPlaceholder(/tytuł treningu/i).fill('Trening testowy');
    await page.getByPlaceholder(/czas trwania/i).fill('-30');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/czas trwania musi być większy od zera/i)).toBeVisible();
    await expect(page.getByText(/nieprawidłowa wartość/i)).toBeVisible();
    await expect(page.getByText(/trening testowy/i)).not.toBeVisible();
  });

  test('B4: Dodawanie treningu z notatkami', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();
    await page.getByPlaceholder(/tytuł treningu/i).fill('Trening z notatkami');
    await page.getByPlaceholder(/czas trwania/i).fill('45');
    await page.locator('select[name="type"]').selectOption('Siła');
    await page.getByPlaceholder(/notatki/i).fill('Trening z notatkami');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/trening zapisany/i)).toBeVisible();
    await expect(page.getByText(/trening z notatkami/i)).toBeVisible();
  });

  test('B5: Dodawanie treningu z typem "Cardio"', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();
    await page.getByPlaceholder(/tytuł treningu/i).fill('Trening Cardio');
    await page.getByPlaceholder(/czas trwania/i).fill('60');
    await page.locator('select[name="type"]').selectOption('Cardio');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/trening zapisany/i)).toBeVisible();
    await expect(page.getByText(/cardio/i)).toBeVisible();
  });

  // --- GRUPA C: SCENARIUSZE ZŁOŻONE (E2E) ---

  test('C1: Pełny scenariusz - sprawdzenie przyrostu XP po dodaniu treningu', async ({ page }) => {
    const initialXp = await page.locator('text=xp').innerText();

    await page.getByRole('link', { name: /^trening$/i }).click();
    await page.getByPlaceholder(/tytuł treningu/i).fill('Pełny trening testowy');
    await page.getByPlaceholder(/czas trwania/i).fill('45');
    await page.locator('select[name="type"]').selectOption('Siła');
    await page.getByPlaceholder(/notatki/i).fill('Pełny trening testowy');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/trening zapisany/i)).toBeVisible();
    await expect(page.getByText(/punkty dodane/i)).toBeVisible();

    const newXp = await page.locator('text=xp').innerText();
    expect(newXp).not.toBe(initialXp);

    await expect(page.getByText(/pełny trening testowy/i)).toBeVisible();
  });

  // --- GRUPA D: WARUNKI BRZEGOWE (EDGE CASES) ---

  test('D1: Dodawanie treningu z bardzo długim tytułem', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();

    const longTitle = 'A'.repeat(200);
    await page.getByPlaceholder(/tytuł treningu/i).fill(longTitle);
    await page.getByPlaceholder(/czas trwania/i).fill('30');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/trening zapisany/i)).toBeVisible();
  });

  test('D2: Dodawanie treningu z minimalnym czasem trwania', async ({ page }) => {
    await page.getByRole('link', { name: /^trening$/i }).click();

    await page.getByPlaceholder(/tytuł treningu/i).fill('Trening 1 minuta');
    await page.getByPlaceholder(/czas trwania/i).fill('1');
    await page.getByRole('button', { name: /zapisz/i }).click();

    await expect(page.getByText(/trening zapisany/i)).toBeVisible();
  });
});

// --- TESTY BEZ AUTORYZACJI (LOGOWANIE / BŁĘDY) ---

test.describe('Niezalogowany użytkownik / Błędy autoryzacji', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('A2 / C2: Logowanie z niepoprawnymi danymi -> błąd', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByText('Zaloguj się')).toBeVisible();

    await page.locator('input[type="email"]').fill('test_nieistniejace@example.com');
    await page.locator('input[type="password"]').fill('Test123!');
    await page.getByRole('button', { name: /zaloguj się/i }).click();

    await expect(page).not.toHaveURL(/dashboard/);
    await expect(page.getByText(/nieprawidłowy email/i)).toBeVisible();
    await expect(page.getByText(/nieprawidłowe hasło/i)).toBeVisible();
    await expect(page.getByText(/trening/i)).not.toBeVisible();
  });
});