export interface LevelProgress {
  level: number;
  xpInLevel: number;
  xpToNextLevel: number;
}

/**
 * Liczy poziom i postęp XP po stronie klienta, lustrzanie do backendowego
 * `exp_utils.compute_level`, dzięki czemu UI pokazuje te same wartości, które
 * przechowuje serwer.
 *
 * Poziom n zaczyna się przy 100 * n*(n-1)/2 XP i wymaga 100*n XP do awansu.
 */
export function computeLevelProgress(totalExp: number): LevelProgress {
  const exp = Math.max(totalExp ?? 0, 0);
  const level = Math.floor((-1 + Math.sqrt(1 + (8 * exp) / 100)) / 2) + 1;
  const levelStart = (100 * (level - 1) * level) / 2;
  const nextLevelStart = (100 * level * (level + 1)) / 2;

  return {
    level,
    xpInLevel: exp - levelStart,
    xpToNextLevel: nextLevelStart - levelStart,
  };
}
