import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MockDataService, Stat, Quest, Achievement, WeeklyActivity } from '../mock-service/mock-data.service';
import { ApiService, UserProfileData, UserSettingsData, LogWorkoutResponse, LogMealResponse } from '../services/api.service';
import { NotificationService } from '../services/notification.service';
import { ToastContainerComponent } from '../components/toast-container/toast-container';
import { WorkoutFormComponent } from '../components/workout-form/workout-form';
import { MealFormComponent } from '../components/meal-form/meal-form';

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
  ],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.css'],
})
export class DashboardComponent implements OnInit {
  activeTab: Tab = 'dashboard';

  // ─── Mock-backed data (until those endpoints are built) ───
  stats: Stat[] = [];
  quests: Quest[] = [];
  achievements: Achievement[] = [];
  weeklyActivity: WeeklyActivity[] = [];

  loadingStats = true;
  loadingQuests = true;
  loadingAchievements = true;
  loadingActivity = true;

  savingQuestId: number | null = null;
  saveSuccessId: number | null = null;
  saveErrorMessage: string | null = null;

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
    private mockService: MockDataService,
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

    this.api.getProfile().subscribe({
      next: (p) => {
        this.profile = p;
        this.editProfile = { ...p };
        this.loadingProfile = false;
      },
      error: () => {
        this.loadingProfile = false;
      },
    });

    this.api.getSettings().subscribe({
      next: (s) => { this.settings = s; this.loadingSettings = false; },
      error: () => { this.loadingSettings = false; },
    });

    this.mockService.getStats().subscribe(s => { this.stats = s; this.loadingStats = false; });
    this.mockService.getQuests().subscribe(q => { this.quests = q; this.loadingQuests = false; });
    this.mockService.getAchievements().subscribe(a => { this.achievements = a; this.loadingAchievements = false; });
    this.mockService.getWeeklyActivity().subscribe(w => { this.weeklyActivity = w; this.loadingActivity = false; });
  }

  setTab(tab: Tab) { this.activeTab = tab; }

  // ─── XP helpers ───
  get xpPercent(): number {
    if (!this.profile) return 0;
    return Math.round((this.profile.xp_in_level / this.profile.xp_to_next_level) * 100);
  }

  // ─── Quest helpers ───
  get completedQuests(): Quest[] { return this.quests.filter(q => q.completed); }
  get pendingQuests(): Quest[]   { return this.quests.filter(q => !q.completed); }

  // ─── Achievement helpers ───
  get unlockedAchievements(): Achievement[] { return this.achievements.filter(a => !a.locked); }
  get lockedAchievements(): Achievement[]   { return this.achievements.filter(a => a.locked); }

  // ─── Activity chart helpers ───
  get maxActivityXp(): number { return Math.max(...this.weeklyActivity.map(w => w.xp), 1); }
  getStatPercent(stat: Stat): number { return Math.round((stat.value / stat.max) * 100); }
  getActivityBarHeight(day: WeeklyActivity): number { return Math.round((day.xp / this.maxActivityXp) * 100); }

  // ─── Quest completion (still mock) ───
  completeQuest(quest: Quest) {
    if (quest.completed || this.savingQuestId !== null) return;
    this.savingQuestId = quest.id;
    this.saveErrorMessage = null;

    this.mockService.saveQuestCompletion(quest.id).subscribe({
      next: (result) => {
        this.savingQuestId = null;
        if (result.success) {
          quest.completed = true;
          this.saveSuccessId = quest.id;
          if (this.profile && result.updatedXp) {
            this.notificationService.showXpToast(result.updatedXp - this.profile.total_exp);
          }
          setTimeout(() => { this.saveSuccessId = null; }, 2500);
        }
      },
      error: () => {
        this.savingQuestId = null;
        this.saveErrorMessage = 'Błąd zapisu. Spróbuj ponownie.';
      },
    });
  }

  // ─── Activity saved handlers (DEV-38, DEV-40) ───
  onWorkoutSaved(response: LogWorkoutResponse): void {
    if (response.exp_granted > 0) {
      this.notificationService.showXpToast(response.exp_granted);
    }
    for (const reward of response.rewards) {
      this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    }
    this.api.getProfile().subscribe(p => { this.profile = p; this.editProfile = { ...p }; });
  }

  onMealSaved(response: LogMealResponse): void {
    if (response.exp_granted > 0) {
      this.notificationService.showXpToast(response.exp_granted);
    }
    for (const reward of response.rewards) {
      this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    }
    this.api.getProfile().subscribe(p => { this.profile = p; this.editProfile = { ...p }; });
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

  getCategoryColor(category: string): string {
    const map: Record<string, string> = {
      'Cardio':       '#e74c3c',
      'Siła':         '#e67e22',
      'Core':         '#f1c40f',
      'Elastyczność': '#2a8f5e',
    };
    return map[category] || '#95a5a6';
  }

  logout() {
    localStorage.removeItem('token');
    this.router.navigate(['/login']);
  }
}
