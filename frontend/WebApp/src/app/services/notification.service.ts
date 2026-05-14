import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface Toast {
  id: number;
  type: 'xp' | 'challenge';
  message: string;
  xpAmount?: number;
  challengeTitle?: string;
  pointsEarned?: number;
}

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private nextId = 1;
  private toastsSubject = new BehaviorSubject<Toast[]>([]);
  toasts$ = this.toastsSubject.asObservable();

  showXpToast(amount: number): void {
    const toast: Toast = {
      id: this.nextId++,
      type: 'xp',
      message: `+${amount} XP`,
      xpAmount: amount,
    };
    this.push(toast, 3000);
  }

  showChallengeToast(title: string, points: number): void {
    const toast: Toast = {
      id: this.nextId++,
      type: 'challenge',
      message: 'Wyzwanie ukończone!',
      challengeTitle: title,
      pointsEarned: points,
    };
    this.push(toast, 5000);
  }

  dismiss(id: number): void {
    this.toastsSubject.next(this.toastsSubject.value.filter(t => t.id !== id));
  }

  private push(toast: Toast, durationMs: number): void {
    this.toastsSubject.next([...this.toastsSubject.value, toast]);
    setTimeout(() => this.dismiss(toast.id), durationMs);
  }
}
