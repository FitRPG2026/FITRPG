import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MockDataService, UserProfile, Stat, Quest, Achievement, WeeklyActivity } from '../mock-service/mock-data.service';

type Tab = 'dashboard' | 'quests' | 'achievements' | 'stats';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.css']
})
export class DashboardComponent implements OnInit {
  activeTab: Tab = 'dashboard';

  profile: UserProfile | null = null;
  stats: Stat[] = [];
  quests: Quest[] = [];
  achievements: Achievement[] = [];
  weeklyActivity: WeeklyActivity[] = [];

  loadingProfile = true;
  loadingStats = true;
  loadingQuests = true;
  loadingAchievements = true;
  loadingActivity = true;

  savingQuestId: number | null = null;
  saveSuccessId: number | null = null;
  saveErrorMessage: string | null = null;

  savingProfile = false;
  profileSaveSuccess = false;

  constructor(
    private mockService: MockDataService,
    private router: Router
  ) {}

  ngOnInit() {
    const token = localStorage.getItem('token');
    if (!token) {
      this.router.navigate(['/login']);
      return;
    }

    this.mockService.getUserProfile().subscribe(p => {
      this.profile = p;
      this.loadingProfile = false;
    });

    this.mockService.getStats().subscribe(s => {
      this.stats = s;
      this.loadingStats = false;
    });

    this.mockService.getQuests().subscribe(q => {
      this.quests = q;
      this.loadingQuests = false;
    });

    this.mockService.getAchievements().subscribe(a => {
      this.achievements = a;
      this.loadingAchievements = false;
    });

    this.mockService.getWeeklyActivity().subscribe(w => {
      this.weeklyActivity = w;
      this.loadingActivity = false;
    });
  }

  setTab(tab: Tab) {
    this.activeTab = tab;
  }

  get xpPercent(): number {
    if (!this.profile) return 0;
    return Math.round((this.profile.xp / this.profile.xpToNext) * 100);
  }

  get completedQuests(): Quest[] {
    return this.quests.filter(q => q.completed);
  }

  get pendingQuests(): Quest[] {
    return this.quests.filter(q => !q.completed);
  }

  get unlockedAchievements(): Achievement[] {
    return this.achievements.filter(a => !a.locked);
  }

  get lockedAchievements(): Achievement[] {
    return this.achievements.filter(a => a.locked);
  }

  get maxActivityXp(): number {
    return Math.max(...this.weeklyActivity.map(w => w.xp), 1);
  }

  getStatPercent(stat: Stat): number {
    return Math.round((stat.value / stat.max) * 100);
  }

  getActivityBarHeight(day: WeeklyActivity): number {
    return Math.round((day.xp / this.maxActivityXp) * 100);
  }

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
            this.profile.xp = result.updatedXp;
          }
          setTimeout(() => { this.saveSuccessId = null; }, 2500);
        }
      },
      error: () => {
        this.savingQuestId = null;
        this.saveErrorMessage = 'Błąd zapisu. Spróbuj ponownie.';
      }
    });
  }

  saveProfile() {
    if (!this.profile || this.savingProfile) return;
    this.savingProfile = true;
    this.profileSaveSuccess = false;

    this.mockService.saveProfileSettings({ name: this.profile.name }).subscribe({
      next: () => {
        this.savingProfile = false;
        this.profileSaveSuccess = true;
        setTimeout(() => { this.profileSaveSuccess = false; }, 2500);
      }
    });
  }

  logout() {
    localStorage.removeItem('token');
    this.router.navigate(['/login']);
  }

  getCategoryColor(category: string): string {
    const map: Record<string, string> = {
      'Cardio': '#e74c3c',
      'Siła': '#e67e22',
      'Core': '#f1c40f',
      'Elastyczność': '#2a8f5e',
    };
    return map[category] || '#95a5a6';
  }
}
