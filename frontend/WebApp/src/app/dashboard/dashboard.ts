import { Component, OnInit, ViewChild, ChangeDetectorRef } from '@angular/core'; 
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import {
  ApiService,
  UserProfileData,
  UserSettingsData,
  LogWorkoutResponse,
  LogMealResponse,
  WorkoutData,
  Stat,
  UserQuest,
  UserChallenge,
  WeeklyActivity,
  WeeklyActivityChartData,
} from '../services/api.service';
import { computeLevelProgress } from '../services/level.util';
import { buildStats } from '../services/stats.util';
import { NotificationService } from '../services/notification.service';
import { ToastContainerComponent } from '../components/toast-container/toast-container';
import { WorkoutFormComponent } from '../components/workout-form/workout-form';
import { MealFormComponent } from '../components/meal-form/meal-form';
import { ProgressComponent } from '../components/progress/progress'; 

import { timeout, catchError, finalize } from 'rxjs/operators';
import { of } from 'rxjs';

type Tab = 'dashboard' | 'quests' | 'achievements' | 'stats' | 'training' | 'profile';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ToastContainerComponent,
    WorkoutFormComponent,
    MealFormComponent,
    ProgressComponent
  ],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.css'],
})
export class DashboardComponent implements OnInit {
  
  @ViewChild(ProgressComponent) progressComponent!: ProgressComponent;

  activeTab: Tab = 'dashboard';
  stats: Stat[] = [];
  quests: UserQuest[] = [];
  challenges: UserChallenge[] = [];
  weeklyActivity: WeeklyActivity[] = [];
  weeklyChartData: WeeklyActivityChartData[] = [];
  maxActivityCount = 1;

  loadingStats = true;
  loadingQuests = true;
  loadingChallenges = true;
  loadingActivity = true;
  loadingChart = true;

  private lastWorkouts: WorkoutData[] = [];
  profile: UserProfileData | null = null;
  loadingProfile = true;

  editProfile: Partial<UserProfileData> = {};
  savingProfile = false;
  profileSaveSuccess = false;
  profileSaveError: string | null = null;

  settings: UserSettingsData = { data_processing_consent: false, profile_public: false };
  loadingSettings = true;
  savingSettings = false;
  settingsSaveSuccess = false;
  private isRefreshing = false;

  readonly goalOptions = [{ value: 'weight_loss', label: 'Redukcja wagi' }, { value: 'muscle_gain', label: 'Budowanie masy' }, { value: 'maintenance', label: 'Utrzymanie formy' }, { value: 'endurance', label: 'Wytrzymałość' }, { value: 'general', label: 'Ogólna sprawność' }];
  readonly activityLevelOptions = [{ value: 'sedentary', label: 'Siedzący tryb życia' }, { value: 'light', label: 'Lekka aktywność' }, { value: 'moderate', label: 'Umiarkowana aktywność' }, { value: 'active', label: 'Aktywny' }, { value: 'very_active', label: 'Bardzo aktywny' }];
  readonly sexOptions = [{ value: 'male', label: 'Mężczyzna' }, { value: 'female', label: 'Kobieta' }, { value: 'other', label: 'Inne' }, { value: 'prefer_not_to_say', label: 'Wolę nie podawać' }];

  constructor(
    private api: ApiService,
    private notificationService: NotificationService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  async ngOnInit() {
    const token = typeof window !== 'undefined' ? localStorage.getItem('jwt_token') : null;
    if (!token) {
      this.router.navigate(['/login']);
      return;
    }

    this.api.getProfile().subscribe({
      next: (p) => {
        this.profile = this.withLevelProgress(p);
        this.loadingProfile = false;
        this.loadSettings();
        this.loadWeeklyActivity();
        this.loadWorkoutsDerived();
        this.loadQuests();
        this.loadChallenges();
      },
      error: () => { this.loadingProfile = false; }
    });
  }

  setTab(tab: Tab) {
    this.activeTab = tab;
    switch (tab) {
      case 'dashboard':
        this.loadProfile();
        this.loadWorkoutsDerived();
        this.loadWeeklyActivity();
        break;
      case 'quests':
        this.loadQuests();
        this.loadChallenges();
        break;
      case 'achievements':
        this.loadChallenges();
        break;
      case 'stats':
        this.loadProfile();
        this.loadWorkoutsDerived();
        break;
    }
  }

  private loadProfile(): void {
    this.api.getProfile().pipe(timeout(15000), catchError(() => of(null))).subscribe({
      next: (p) => {
        if (p) {
          this.profile = this.withLevelProgress(p);
          this.editProfile = { ...this.profile };
          this.recomputeDerived();
        }
        this.loadingProfile = false;
      },
      error: () => { this.loadingProfile = false; },
    });
  }

  private loadWeeklyActivity(): void {
    this.loadingChart = true;
    this.api.getWeeklyActivity().subscribe({
      next: (data) => {
        this.weeklyChartData = data;
        const max = Math.max(...data.map(d => (Number(d.workouts_count) || 0) + (Number(d.meals_count) || 0)));
        this.maxActivityCount = max > 0 ? max : 1;
        this.loadingChart = false;
        this.cdr.detectChanges();
      },
      error: () => { this.loadingChart = false; this.cdr.detectChanges(); }
    });
  }

  private loadSettings(): void {
    this.api.getSettings().subscribe({
      next: (s) => { this.settings = s; this.loadingSettings = false; },
      error: () => { this.loadingSettings = false; },
    });
  }

  private loadQuests(): void {
    this.api.getQuests().subscribe({
      next: (q) => { this.quests = q; this.loadingQuests = false; },
      error: () => { this.quests = []; this.loadingQuests = false; },
    });
  }

  private loadChallenges(): void {
    this.api.getChallenges().subscribe({
      next: (c) => { this.challenges = c; this.loadingChallenges = false; },
      error: () => { this.challenges = []; this.loadingChallenges = false; },
    });
  }

  private loadWorkoutsDerived(): void {
    this.loadingStats = true;
    this.api.getWorkouts().pipe(
      timeout(15000),
      catchError(() => of([] as WorkoutData[])),
      finalize(() => { this.loadingStats = false; this.cdr.detectChanges(); })
    ).subscribe({
      next: (workouts) => {
        this.lastWorkouts = workouts || [];
        this.recomputeDerived();
      }
    });
  }

  private recomputeDerived(): void {
    const streak = this.profile?.current_streak_days ?? 0;
    this.stats = buildStats(this.lastWorkouts || [], streak);
    this.cdr.detectChanges();
  }

  private refreshAfterActivity(): void {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    setTimeout(() => {
      this.loadProfile();
      this.loadWeeklyActivity();
      this.loadWorkoutsDerived();
      this.loadQuests();
      this.loadChallenges();
      this.progressComponent?.loadWorkouts();
      this.isRefreshing = false;
    }, 500);
  }

  private withLevelProgress(profile: UserProfileData): UserProfileData {
    const { level, xpInLevel, xpToNextLevel } = computeLevelProgress(profile.total_exp);
    return { ...profile, level, xp_in_level: xpInLevel, xp_to_next_level: xpToNextLevel, longest_streak_days: profile.longest_streak_days ?? 0 };
  }

  get xpPercent(): number {
    if (!this.profile || !this.profile.xp_to_next_level) return 0;
    return Math.round((this.profile.xp_in_level / this.profile.xp_to_next_level) * 100);
  }

  get completedQuests(): UserQuest[] { return this.quests.filter(q => q.status === 'completed' || q.status === 'claimed'); }
  get pendingQuests(): UserQuest[] { return this.quests.filter(q => q.status !== 'completed' && q.status !== 'claimed'); }

  get completedChallenges(): UserChallenge[] { return this.challenges.filter(c => c.status === 'completed' || c.status === 'claimed'); }
  get activeChallenges(): UserChallenge[] { return this.challenges.filter(c => c.status !== 'completed' && c.status !== 'claimed' && c.status !== 'failed'); }

  getStatPercent(stat: Stat): number { return Math.round((stat.value / stat.max) * 100); }
  getChallengeProgressPercent(c: UserChallenge): number {
    if (!c.challenge.goal_value) return 0;
    return Math.min(100, Math.round((c.progress_value / c.challenge.goal_value) * 100));
  }

  onWorkoutSaved(response: LogWorkoutResponse): void {
    if (response.exp_granted > 0) this.notificationService.showXpToast(response.exp_granted);
    for (const reward of response.rewards) this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    this.refreshAfterActivity();
  }

  onMealSaved(response: LogMealResponse): void {
    const expGranted = response.exp_granted ?? 0;
    if (expGranted > 0) this.notificationService.showXpToast(expGranted);
    for (const reward of response.rewards ?? []) this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    this.refreshAfterActivity();
  }

  saveProfile(): void {
    if (this.savingProfile) return;
    this.savingProfile = true;
    this.api.updateProfile(this.editProfile).subscribe({
      next: (p) => {
        this.profile = this.withLevelProgress(p);
        this.editProfile = { ...this.profile };
        this.savingProfile = false;
        this.profileSaveSuccess = true;
        this.recomputeDerived();
        setTimeout(() => { this.profileSaveSuccess = false; }, 2500);
      },
      error: () => { this.savingProfile = false; }
    });
  }

  saveSettings(): void {
    if (this.savingSettings) return;
    this.savingSettings = true;
    this.api.updateSettings(this.settings).subscribe({
      next: (s) => { this.settings = s; this.savingSettings = false; this.settingsSaveSuccess = true; setTimeout(() => { this.settingsSaveSuccess = false; }, 2500); },
      error: () => { this.savingSettings = false; }
    });
  }

  logout() {
    localStorage.removeItem('jwt_token');
    this.router.navigate(['/login']);
  }
}
