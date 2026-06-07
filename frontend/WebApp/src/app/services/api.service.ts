import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';

import { environment } from '../../environments/environment';

// ─── Domena grywalizacji (statystyki, questy, osiągnięcia) ───
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
  minutes: number;
}

export interface ExerciseRow {
  exercise_name: string;
  exercise_order: number;
  exercise_group: string;
  sets: number | null;
  reps: number | null;
  weight_kg: number | null;
  notes: string;
}

export interface ChallengeReward {
  challenge_id: number;
  title: string;
  points_earned: number;
}

export interface LogWorkoutRequest {
  title: string;
  workout_type: string;
  activity_category: string;
  duration_min: number;
  performed_at: string;
  notes: string;
  exercises: ExerciseRow[];
}

export interface LogWorkoutResponse {
  status: string;
  workout_id: number;
  exp_granted: number;
  rewards: ChallengeReward[];
}
export interface WorkoutData {
  id?: number;                          
  workout_type: string;
  title: string;
  performed_at: string;
  duration_min: number | null;
  health_score: number | null;
  notes?: string | null;                
  activity_category?: string | null;    
  activity_name?: string | null;        
  exp_amount?: number;
  exercises_json?: string;
}

export interface LogMealRequest {
  title: string;
  meal_type: string;
  eaten_at: string;
  notes: string;
  health_score: number;
}

export interface LogMealResponse {
  status: string;
  meal_id: number;
  exp_granted: number;
  rewards: ChallengeReward[];
}

export interface UserProfileData {
  user_id: number;
  username: string | null;
  display_name: string | null;
  birth_date: string | null;
  sex: string | null;
  height_cm: number | null;
  weight_kg: number | null;
  goal: string | null;
  activity_level: string | null;
  total_exp: number;
  level: number;
  xp_in_level: number;
  xp_to_next_level: number;
  current_streak_days: number;
  longest_streak_days: number;
}

export interface UpdateProfileRequest {
  username?: string;
  display_name?: string;
  birth_date?: string;
  sex?: string;
  height_cm?: number;
  weight_kg?: number;
  goal?: string;
  activity_level?: string;
}

export interface UserSettingsData {
  data_processing_consent: boolean;
  profile_public: boolean;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly baseUrl = `${environment.apiUrl}/api`;

  constructor(private http: HttpClient) {}

  private headers(): HttpHeaders {
    let token = '';
    if (typeof window !== 'undefined') {
      token = localStorage.getItem('jwt_token') || localStorage.getItem('access_token') || localStorage.getItem('token') || '';
    }
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }

  logWorkout(req: LogWorkoutRequest): Observable<LogWorkoutResponse> {
    return this.http.post<LogWorkoutResponse>(`${this.baseUrl}/workouts`, req, { headers: this.headers() });
  }

  logMeal(req: LogMealRequest): Observable<LogMealResponse> {
    return this.http.post<LogMealResponse>(`${this.baseUrl}/meals`, req, { headers: this.headers() });
  }

  getProfile(): Observable<UserProfileData> {
    return this.http.get<UserProfileData>(`${this.baseUrl}/profile`, { headers: this.headers() });
  }

  updateProfile(req: UpdateProfileRequest): Observable<UserProfileData> {
    return this.http.put<UserProfileData>(`${this.baseUrl}/profile`, req, { headers: this.headers() });
  }

  getSettings(): Observable<UserSettingsData> {
    return this.http.get<UserSettingsData>(`${this.baseUrl}/settings`, { headers: this.headers() });
  }

  updateSettings(req: UserSettingsData): Observable<UserSettingsData> {
    return this.http.put<UserSettingsData>(`${this.baseUrl}/settings`, req, { headers: this.headers() });
  }
  getWorkouts(): Observable<WorkoutData[]> {
    return this.http.get<WorkoutData[]>(`${this.baseUrl}/workouts`, { headers: this.headers() });
  }

  // ─── Grywalizacja ───────────────────────────────────────────────────────────
  // TODO(Dev-73): podmień na this.http.get<Stat[]>(`${this.baseUrl}/stats`, ...)
  // gdy backend udostępni endpoint statystyk. Na razie wartości tymczasowe.
  getStats(): Observable<Stat[]> {
    return of<Stat[]>([
      { name: 'Siła',         value: 74, max: 100, icon: '💪', color: '#e74c3c' },
      { name: 'Wytrzymałość', value: 58, max: 100, icon: '🏃', color: '#2a8f5e' },
      { name: 'Zwinność',     value: 43, max: 100, icon: '⚡', color: '#f39c12' },
      { name: 'Wola',         value: 81, max: 100, icon: '🧠', color: '#9b59b6' },
    ]);
  }

  // TODO(Dev-74): podmień na GET `${this.baseUrl}/quests` gdy backend wyzwań będzie gotowy.
  getQuests(): Observable<Quest[]> {
    return of<Quest[]>([]);
  }

  // TODO(Dev-74): podmień na GET `${this.baseUrl}/achievements` gdy backend wyzwań będzie gotowy.
  getAchievements(): Observable<Achievement[]> {
    return of<Achievement[]>([]);
  }
}
