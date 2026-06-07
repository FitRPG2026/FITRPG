import { Component, OnInit, ViewChild } from '@angular/core'; 
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
  Quest,
  Achievement,
  WeeklyActivity,
} from '../services/api.service';
import { computeLevelProgress } from '../services/level.util';
import { NotificationService } from '../services/notification.service';
import { ToastContainerComponent } from '../components/toast-container/toast-container';
import { WorkoutFormComponent } from '../components/workout-form/workout-form';
import { MealFormComponent } from '../components/meal-form/meal-form';
import { ProgressComponent } from '../components/progress/progress'; 

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

  // ─── Dane grywalizacji (przez ApiService) ───
  // Statystyki to wartości tymczasowe (Dev-73), questy/osiągnięcia czekają na
  // backend wyzwań (Dev-74) i na razie przychodzą puste.
  stats: Stat[] = [];
  quests: Quest[] = [];
  achievements: Achievement[] = [];
  weeklyActivity: WeeklyActivity[] = [];

  loadingStats = true;
  loadingQuests = true;
  loadingAchievements = true;
  loadingActivity = true;

  // ─── Profile (real API) ───
  profile: UserProfileData | null = null;
  loadingProfile = true;

  // ─── Profile edit form ───
  editProfile: Partial<UserProfileData> = {};
  savingProfile = false;
  profileSaveSuccess = false;
  profileSaveError: string | null = null;

  // ─── Settings ───
  settings: UserSettingsData = { data_processing_consent: false, profile_public: false };
  loadingSettings = true;
  savingSettings = false;
  settingsSaveSuccess = false;

  readonly goalOptions = [
    { value: 'weight_loss',   label: 'Redukcja wagi' },
    { value: 'muscle_gain',   label: 'Budowanie masy' },
    { value: 'maintenance',   label: 'Utrzymanie formy' },
    { value: 'endurance',     label: 'Wytrzymałość' },
    { value: 'general',       label: 'Ogólna sprawność' },
  ];

  readonly activityLevelOptions = [
    { value: 'sedentary',    label: 'Siedzący tryb życia' },
    { value: 'light',        label: 'Lekka aktywność' },
    { value: 'moderate',     label: 'Umiarkowana aktywność' },
    { value: 'active',       label: 'Aktywny' },
    { value: 'very_active',  label: 'Bardzo aktywny' },
  ];

  readonly sexOptions = [
    { value: 'male',             label: 'Mężczyzna' },
    { value: 'female',           label: 'Kobieta' },
    { value: 'other',            label: 'Inne' },
    { value: 'prefer_not_to_say',label: 'Wolę nie podawać' },
  ];

  constructor(
    private api: ApiService,
    private notificationService: NotificationService,
    private router: Router,
  ) {}

  ngOnInit() {
    const token = typeof window !== 'undefined' ? localStorage.getItem('jwt_token') : null;
    if (!token) {
      this.router.navigate(['/login']);
      return;
    }

    this.loadProfile();
    this.loadSettings();
    this.loadStats();
    this.loadQuests();
    this.loadAchievements();
    this.loadWeeklyActivity();
  }

  // Przełączenie zakładki dociąga świeże dane, by stany (ukończone questy,
  // punkty, aktywność) nie wymagały ręcznego odświeżenia ekranu (Dev-86).
  setTab(tab: Tab) {
    this.activeTab = tab;
    switch (tab) {
      case 'dashboard':
        this.loadProfile();
        this.loadWeeklyActivity();
        break;
      case 'quests':
        this.loadQuests();
        break;
      case 'achievements':
        this.loadAchievements();
        break;
      case 'stats':
        this.loadProfile();
        this.loadStats();
        break;
    }
  }

  // ─── Ładowanie danych ───
  private loadProfile(): void {
    this.api.getProfile().subscribe({
      next: (p) => {
        this.profile = this.withLevelProgress(p);
        this.editProfile = { ...this.profile };
        this.loadingProfile = false;
      },
      error: () => { this.loadingProfile = false; },
    });
  }

  private loadSettings(): void {
    this.api.getSettings().subscribe({
      next: (s) => { this.settings = s; this.loadingSettings = false; },
      error: () => { this.loadingSettings = false; },
    });
  }

  private loadStats(): void {
    this.api.getStats().subscribe({
      next: (s) => { this.stats = s; this.loadingStats = false; },
      error: () => { this.loadingStats = false; },
    });
  }

  private loadQuests(): void {
    this.api.getQuests().subscribe({
      next: (q) => { this.quests = q; this.loadingQuests = false; },
      error: () => { this.quests = []; this.loadingQuests = false; },
    });
  }

  private loadAchievements(): void {
    this.api.getAchievements().subscribe({
      next: (a) => { this.achievements = a; this.loadingAchievements = false; },
      error: () => { this.achievements = []; this.loadingAchievements = false; },
    });
  }

  private loadWeeklyActivity(): void {
    this.loadingActivity = true;
    this.api.getWorkouts().subscribe({
      next: (workouts) => { this.weeklyActivity = this.buildWeeklyActivity(workouts); this.loadingActivity = false; },
      error: () => { this.weeklyActivity = this.buildWeeklyActivity([]); this.loadingActivity = false; },
    });
  }

  // Wzbogaca profil o policzony lokalnie poziom i postęp XP, bo backend
  // zwraca tylko total_exp. Dzięki temu pasek XP i etykieta poziomu są
  // spójne między dashboardem a pozostałymi ekranami (Dev-87).
  private withLevelProgress(profile: UserProfileData): UserProfileData {
    const { level, xpInLevel, xpToNextLevel } = computeLevelProgress(profile.total_exp);
    return {
      ...profile,
      level,
      xp_in_level: xpInLevel,
      xp_to_next_level: xpToNextLevel,
      longest_streak_days: profile.longest_streak_days ?? 0,
    };
  }

  // Buduje wykres aktywności bieżącego tygodnia z realnie zapisanych treningów,
  // aby dashboard zgadzał się z ekranem "Historia Twoich Walk" (Dev-87).
  private buildWeeklyActivity(workouts: WorkoutData[]): WeeklyActivity[] {
    const labels = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];
    const week: WeeklyActivity[] = labels.map((day) => ({ day, workouts: 0, minutes: 0 }));
    const weekStart = this.startOfWeek(new Date());

    for (const workout of workouts) {
      const performed = new Date(workout.performed_at);
      if (performed < weekStart) continue;
      const index = (performed.getDay() + 6) % 7; // 0 = poniedziałek
      week[index].workouts += 1;
      week[index].minutes += workout.duration_min ?? 0;
    }
    return week;
  }

  private startOfWeek(date: Date): Date {
    const monday = new Date(date);
    const offset = (monday.getDay() + 6) % 7;
    monday.setDate(monday.getDate() - offset);
    monday.setHours(0, 0, 0, 0);
    return monday;
  }

  // ─── XP helpers ───
  get xpPercent(): number {
    if (!this.profile || !this.profile.xp_to_next_level) return 0;
    return Math.round((this.profile.xp_in_level / this.profile.xp_to_next_level) * 100);
  }

  // ─── Quest helpers ───
  get completedQuests(): Quest[] { return this.quests.filter(q => q.completed); }
  get pendingQuests(): Quest[]   { return this.quests.filter(q => !q.completed); }

  // ─── Achievement helpers ───
  get unlockedAchievements(): Achievement[] { return this.achievements.filter(a => !a.locked); }
  get lockedAchievements(): Achievement[]   { return this.achievements.filter(a => a.locked); }

  // ─── Activity chart helpers ───
  get maxActivityMinutes(): number { return Math.max(...this.weeklyActivity.map(w => w.minutes), 1); }
  getStatPercent(stat: Stat): number { return Math.round((stat.value / stat.max) * 100); }
  getActivityBarHeight(day: WeeklyActivity): number { return Math.round((day.minutes / this.maxActivityMinutes) * 100); }

  // ─── Activity saved handlers (DEV-38, DEV-40) ───
  onWorkoutSaved(response: LogWorkoutResponse): void {
    if (response.exp_granted > 0) {
      this.notificationService.showXpToast(response.exp_granted);
    }
    for (const reward of response.rewards) {
      this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    }
    this.refreshAfterActivity();
  }

  onMealSaved(response: LogMealResponse): void {
    if (response.exp_granted > 0) {
      this.notificationService.showXpToast(response.exp_granted);
    }
    for (const reward of response.rewards) {
      this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    }
    this.refreshAfterActivity();
  }

  // Po zalogowaniu aktywności odświeża profil, wykres tygodnia oraz historię
  // treningów, dzięki czemu dane aktualizują się bez przeładowania (Dev-86/87).
  private refreshAfterActivity(): void {
    this.loadProfile();
    this.loadWeeklyActivity();
    this.progressComponent?.loadWorkouts();
  }

  // ─── Profile save ───
  saveProfile(): void {
    if (this.savingProfile) return;
    this.savingProfile = true;
    this.profileSaveSuccess = false;
    this.profileSaveError = null;

    this.api.updateProfile({
      username:       this.editProfile.username ?? undefined,
      display_name:   this.editProfile.display_name ?? undefined,
      birth_date:     this.editProfile.birth_date ?? undefined,
      sex:            this.editProfile.sex ?? undefined,
      height_cm:      this.editProfile.height_cm ?? undefined,
      weight_kg:      this.editProfile.weight_kg ?? undefined,
      goal:           this.editProfile.goal ?? undefined,
      activity_level: this.editProfile.activity_level ?? undefined,
    }).subscribe({
      next: (p) => {
        this.profile = p;
        this.editProfile = { ...p };
        this.savingProfile = false;
        this.profileSaveSuccess = true;
        setTimeout(() => { this.profileSaveSuccess = false; }, 2500);
      },
      error: (err) => {
        this.savingProfile = false;
        this.profileSaveError = err?.error?.detail ?? 'Błąd zapisu. Spróbuj ponownie.';
      },
    });
  }

  // ─── Settings save ───
  saveSettings(): void {
    if (this.savingSettings) return;
    this.savingSettings = true;
    this.settingsSaveSuccess = false;

    this.api.updateSettings(this.settings).subscribe({
      next: (s) => {
        this.settings = s;
        this.savingSettings = false;
        this.settingsSaveSuccess = true;
        setTimeout(() => { this.settingsSaveSuccess = false; }, 2500);
      },
      error: () => { this.savingSettings = false; },
    });
  }

  logout() {
    localStorage.removeItem('token');
    this.router.navigate(['/login']);
  }
} // <-- Ostatnia klamra zamykająca całą klasę Componentu
