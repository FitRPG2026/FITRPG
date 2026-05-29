import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

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
}
