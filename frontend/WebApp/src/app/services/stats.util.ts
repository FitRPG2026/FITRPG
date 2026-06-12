import { WorkoutData, Stat, WeeklyActivity } from './api.service';

const WEEK_LABELS = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];

function startOfWeek(date: Date): Date {
  const monday = new Date(date);
  const offset = (monday.getDay() + 6) % 7; // 0 = poniedziałek
  monday.setDate(monday.getDate() - offset);
  monday.setHours(0, 0, 0, 0);
  return monday;
}

function clamp(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)));
}

/**
 * Buduje wykres aktywności bieżącego tygodnia z realnie zapisanych treningów,
 * aby dashboard zgadzał się z historią treningów (Dev-87).
 */
export function buildWeeklyActivity(workouts: WorkoutData[]): WeeklyActivity[] {
  const week: WeeklyActivity[] = WEEK_LABELS.map((day) => ({ day, workouts: 0, minutes: 0 }));
  const weekStart = startOfWeek(new Date());

  for (const workout of workouts) {
    // Jeśli z bazy przyjdzie pusty string lub null, pomijamy ten trening
    if (!workout.performed_at) continue; 
    
    const performed = new Date(workout.performed_at);
    // Jeśli data jest w złym formacie (np. samo słowo zamiast daty ISO), pomijamy
    if (isNaN(performed.getTime())) continue; 
    // -------------------------------

    if (performed < weekStart) continue;
    
    const index = (performed.getDay() + 6) % 7;
    week[index].workouts += 1;
    week[index].minutes += workout.duration_min ?? 0;
  }
  return week;
  // for (const workout of workouts) {
  //   const performed = new Date(workout.performed_at);
  //   if (performed < weekStart) continue;
  //   const index = (performed.getDay() + 6) % 7;
  //   week[index].workouts += 1;
  //   week[index].minutes += workout.duration_min ?? 0;
  // }
  // return week;
}

/**
 * Wylicza atrybuty bohatera z realnej historii treningów (endpoint /workouts)
 * oraz passy z profilu (Dev-73). Każdy atrybut jest skalowany 0–100:
 *  - Siła         ← łączny czas treningów siłowych
 *  - Wytrzymałość ← łączny czas cardio
 *  - Zwinność     ← łączny czas treningów sportowych
 *  - Wola         ← konsekwencja (passa dni + liczba treningów)
 */
export function buildStats(workouts: WorkoutData[], currentStreakDays: number): Stat[] {
  let strengthMin = 0;
  let cardioMin = 0;
  let agilityMin = 0;

  for (const workout of workouts) {
    const minutes = workout.duration_min ?? 0;
    switch (workout.workout_type) {
      case 'strength': strengthMin += minutes; break;
      case 'cardio':   cardioMin += minutes;   break;
      case 'sport':    agilityMin += minutes;  break;
      // 'other' nie mapuje się na konkretny atrybut
    }
  }

  // ~600 min (10 h) treningu danego typu daje maksymalną wartość atrybutu.
  const fromMinutes = (minutes: number) => clamp(minutes / 6);
  const willpower = clamp(currentStreakDays * 5 + workouts.length * 3);

  return [
    { name: 'Siła',         value: fromMinutes(strengthMin), max: 100, icon: '💪', color: '#e74c3c' },
    { name: 'Wytrzymałość', value: fromMinutes(cardioMin),   max: 100, icon: '🏃', color: '#2a8f5e' },
    { name: 'Zwinność',     value: fromMinutes(agilityMin),  max: 100, icon: '⚡', color: '#f39c12' },
    { name: 'Wola',         value: willpower,                max: 100, icon: '🧠', color: '#9b59b6' },
  ];
}
