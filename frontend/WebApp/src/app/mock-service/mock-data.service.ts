import { Injectable } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';

export interface UserProfile {
  name: string;
  level: number;
  xp: number;
  xpToNext: number;
  class: string;
  avatar: string;
  streak: number;
  joinDate: string;
}

export interface Stat {
  name: string;
  value: number;
  max: number;
  icon: string;
  color: string;
}

export interface Quest {
  id: number;
  title: string;
  description: string;
  xp: number;
  completed: boolean;
  category: string;
  dueDate: string;
}

export interface Achievement {
  id: number;
  title: string;
  description: string;
  icon: string;
  unlockedAt: string | null;
  locked: boolean;
}

export interface WeeklyActivity {
  day: string;
  workouts: number;
  xp: number;
}

export interface SaveResult {
  success: boolean;
  message: string;
  updatedXp?: number;
}

@Injectable({ providedIn: 'root' })
export class MockDataService {

  getUserProfile() {
    return of<UserProfile>({
      name: 'Wojtek Kowalski',
      level: 12,
      xp: 3420,
      xpToNext: 5000,
      class: 'Wojownik Kondycji',
      avatar: '🧙',
      streak: 7,
      joinDate: '2024-01-15'
    }).pipe(delay(600));
  }

  getStats() {
    return of<Stat[]>([
      { name: 'Siła', value: 74, max: 100, icon: '💪', color: '#e74c3c' },
      { name: 'Wytrzymałość', value: 58, max: 100, icon: '🏃', color: '#2a8f5e' },
      { name: 'Zwinność', value: 43, max: 100, icon: '⚡', color: '#f39c12' },
      { name: 'Wola', value: 81, max: 100, icon: '🧠', color: '#9b59b6' },
    ]).pipe(delay(800));
  }

  getQuests() {
    return of<Quest[]>([
      { id: 1, title: '10 000 kroków', description: 'Przejdź 10 000 kroków w ciągu dnia', xp: 150, completed: true, category: 'Cardio', dueDate: 'Dziś' },
      { id: 2, title: 'Pompki x50', description: 'Wykonaj 50 pompek (można w seriach)', xp: 200, completed: false, category: 'Siła', dueDate: 'Dziś' },
      { id: 3, title: 'Rozciąganie poranne', description: '10 minut rozciągania po przebudzeniu', xp: 80, completed: false, category: 'Elastyczność', dueDate: 'Dziś' },
      { id: 4, title: 'Bieg 5km', description: 'Przebieg 5 kilometrów bez przerwy', xp: 350, completed: false, category: 'Cardio', dueDate: 'Jutro' },
      { id: 5, title: 'Plank 2 minuty', description: 'Utrzymaj pozycję planku przez 2 minuty', xp: 120, completed: true, category: 'Core', dueDate: 'Dziś' },
      { id: 6, title: 'Pływanie 30 min', description: 'Przepłyń przez 30 minut w basenie', xp: 280, completed: false, category: 'Cardio', dueDate: 'Pojutrze' },
    ]).pipe(delay(700));
  }

  getAchievements() {
    return of<Achievement[]>([
      { id: 1, title: 'Pierwszy krok', description: 'Ukończ swój pierwszy quest', icon: '🥇', unlockedAt: '2024-01-16', locked: false },
      { id: 2, title: 'Tygodniowy wojownik', description: '7 dni z rzędu aktywności', icon: '🔥', unlockedAt: '2024-01-22', locked: false },
      { id: 3, title: 'Żelazna wola', description: 'Ukończ 50 questów', icon: '⚔️', unlockedAt: '2024-03-10', locked: false },
      { id: 4, title: 'Maraton', description: 'Przebiegaj łącznie 42km', icon: '🏅', unlockedAt: null, locked: true },
      { id: 5, title: 'Legenda sali', description: 'Osiągnij poziom 20', icon: '👑', unlockedAt: null, locked: true },
      { id: 6, title: 'Mistrz cardio', description: 'Wykonaj 100 questów cardio', icon: '💨', unlockedAt: null, locked: true },
    ]).pipe(delay(900));
  }

  getWeeklyActivity() {
    return of<WeeklyActivity[]>([
      { day: 'Pon', workouts: 2, xp: 380 },
      { day: 'Wt', workouts: 1, xp: 150 },
      { day: 'Śr', workouts: 3, xp: 620 },
      { day: 'Czw', workouts: 0, xp: 0 },
      { day: 'Pt', workouts: 2, xp: 450 },
      { day: 'Sob', workouts: 4, xp: 890 },
      { day: 'Nd', workouts: 1, xp: 200 },
    ]).pipe(delay(700));
  }

  saveQuestCompletion(questId: number) {
    return of<SaveResult>({
      success: true,
      message: 'Quest ukończony! XP dodane.',
      updatedXp: 3420 + 200
    }).pipe(delay(1000));
  }

  saveProfileSettings(data: Partial<UserProfile>) {
    return of<SaveResult>({
      success: true,
      message: 'Profil zaktualizowany pomyślnie!'
    }).pipe(delay(1000));
  }
}
