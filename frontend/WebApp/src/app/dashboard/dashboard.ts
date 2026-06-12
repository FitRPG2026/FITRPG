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
  UserQuest,
  UserChallenge,
  WeeklyActivity,
} from '../services/api.service';
import { computeLevelProgress } from '../services/level.util';
import { buildStats, buildWeeklyActivity } from '../services/stats.util';
import { NotificationService } from '../services/notification.service';
import { ToastContainerComponent } from '../components/toast-container/toast-container';
import { WorkoutFormComponent } from '../components/workout-form/workout-form';
import { MealFormComponent } from '../components/meal-form/meal-form';
import { ProgressComponent } from '../components/progress/progress'; 

import { timeout, catchError } from 'rxjs/operators';
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

  // ─── Dane grywalizacji ───
  // Statystyki liczone z historii treningów (/workouts). Questy i wyzwania
  // pochodzą z backendu wyzwań (Dev-74).
  stats: Stat[] = [];
  quests: UserQuest[] = [];
  challenges: UserChallenge[] = [];
  weeklyActivity: WeeklyActivity[] = [];

  loadingStats = true;
  loadingQuests = true;
  loadingChallenges = true;
  loadingActivity = true;

  // Ostatnio pobrana historia treningów — źródło statystyk i wykresu tygodnia.
  private lastWorkouts: WorkoutData[] = [];

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
    this.loadWorkoutsDerived();
    this.loadQuests();
    this.loadChallenges();
  }

  // Przełączenie zakładki dociąga świeże dane, by stany (ukończone questy,
  // punkty, aktywność) nie wymagały ręcznego odświeżenia ekranu (Dev-86).
  setTab(tab: Tab) {
    this.activeTab = tab;
    switch (tab) {
      case 'dashboard':
        this.loadProfile();
        this.loadWorkoutsDerived();
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

  // ─── Ładowanie danych ───
  // private loadProfile(): void {
  //   this.api.getProfile().subscribe({
  //     next: (p) => {
  //       this.profile = this.withLevelProgress(p);
  //       this.editProfile = { ...this.profile };
  //       this.loadingProfile = false;
  //       this.recomputeDerived(); // passa wpływa na atrybut "Wola"
  //     },
  //     error: () => { this.loadingProfile = false; },
  //   });
  // }
//   private loadProfile(): void {
//   this.api.getProfile()
//     .pipe(
//       timeout(15000),
//       catchError(() => of(null)),
//     )
//     .subscribe({
//       next: (p) => {
//         if (p) {
//           this.profile = this.withLevelProgress(p);
//           this.editProfile = { ...this.profile };
//           this.recomputeDerived();
//         }
//         this.loadingProfile = false;
//       },
//       error: () => { this.loadingProfile = false; },
//     });
// }
private loadProfile(): void {
  this.api.getProfile()
    .pipe(
      timeout(15000),
      catchError(() => of(null)),
    )
    .subscribe({
      next: (p) => {
        if (p) {
          try {
            this.profile = this.withLevelProgress(p);
            this.editProfile = { ...this.profile };
            this.recomputeDerived();
          } catch (e) {
            console.error("Błąd podczas przeliczania danych profilu:", e);
          }
        }
        // Gwarancja zamknięcia loadera
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

  // Pobiera historię treningów i przelicza z niej statystyki oraz wykres
  // aktywności tygodniowej — jedno źródło danych dla dashboardu i statystyk
  // (Dev-73 / Dev-87).
  // private loadWorkoutsDerived(): void {
  //   this.loadingActivity = true;
  //   this.loadingStats = true;
  //   this.api.getWorkouts().subscribe({
  //     next: (workouts) => { this.lastWorkouts = workouts; this.recomputeDerived(); this.finishWorkoutLoading(); },
  //     error: () => { this.lastWorkouts = []; this.recomputeDerived(); this.finishWorkoutLoading(); },
  //   });
  // }
// 1. Zabezpieczona metoda ładująca treningi i statystyki
  private loadWorkoutsDerived(): void {
    this.loadingActivity = true;
    this.loadingStats = true;
    
    this.api.getWorkouts()
      .pipe(
        timeout(15000),
        catchError(() => of([] as WorkoutData[]))
      )
      .subscribe({
        next: (workouts) => {
          this.lastWorkouts = workouts || [];
          this.recomputeDerived();
        },
        error: (err) => {
          console.error("Błąd ładowania treningów:", err);
          this.lastWorkouts = [];
          this.recomputeDerived();
        }
      });
  }

  // 2. Metoda przeliczająca - BEZ wywołań settimeoutów czy innych pułapek
  private recomputeDerived(): void {
    try {
      const streak = this.profile?.current_streak_days ?? 0;
      const safeWorkouts = this.lastWorkouts || [];
      
      this.stats = buildStats(safeWorkouts, streak);
      this.weeklyActivity = buildWeeklyActivity(safeWorkouts);
    } catch (e) {
      console.error("Błąd w recomputeDerived:", e);
    } finally {
      // TO JEST KLUCZOWE: Zawsze wyłączamy loadery na koniec
      this.loadingStats = false;
      this.loadingActivity = false;
      this.isRefreshing = false; // Reset flagi pętli
    }
  }

  // 3. Dodaj flagę do klasy
  private isRefreshing = false;

  private refreshAfterActivity(): void {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    
    // Używamy setTimeout, żeby odświeżanie nastąpiło po zakończeniu obecnego cyklu Angulara
    setTimeout(() => {
      this.loadProfile();
      this.loadWorkoutsDerived();
      this.loadQuests();
      this.loadChallenges();
      this.progressComponent?.loadWorkouts();
      this.isRefreshing = false;
    }, 500);
  }
  private finishWorkoutLoading(): void {
    this.loadingActivity = false;
    this.loadingStats = false;
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

  // ─── XP helpers ───
  get xpPercent(): number {
    if (!this.profile || !this.profile.xp_to_next_level) return 0;
    return Math.round((this.profile.xp_in_level / this.profile.xp_to_next_level) * 100);
  }

  // ─── Quest helpers ───
  get completedQuests(): UserQuest[] { return this.quests.filter(q => q.status === 'completed'); }
  get pendingQuests(): UserQuest[]   { return this.quests.filter(q => q.status !== 'completed'); }

  // ─── Challenge helpers ───
  get completedChallenges(): UserChallenge[] { return this.challenges.filter(c => c.status === 'completed'); }
  get activeChallenges(): UserChallenge[]    { return this.challenges.filter(c => c.status !== 'completed'); }

  getQuestProgressPercent(q: UserQuest): number {
    if (!q.quest.target_value) return 0;
    return Math.min(100, Math.round((q.progress_value / q.quest.target_value) * 100));
  }

  getChallengeProgressPercent(c: UserChallenge): number {
    if (!c.challenge.goal_value) return 0;
    return Math.min(100, Math.round((c.progress_value / c.challenge.goal_value) * 100));
  }

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
    const expGranted = response.exp_granted ?? 0;
    if (expGranted > 0) {
      this.notificationService.showXpToast(expGranted);
    }
    for (const reward of response.rewards ?? []) {
      this.notificationService.showChallengeToast(reward.title, reward.points_earned);
    }
    this.refreshAfterActivity();
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
        this.profile = this.withLevelProgress(p);
        this.editProfile = { ...this.profile };
        this.savingProfile = false;
        this.profileSaveSuccess = true;
        this.recomputeDerived();
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
    localStorage.removeItem('jwt_token');
    this.router.navigate(['/login']);
  }
} // <-- Ostatnia klamra zamykająca całą klasę Componentu

