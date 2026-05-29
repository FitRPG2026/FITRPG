import { Component, EventEmitter, Input, OnDestroy, Output, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { interval, Subscription } from 'rxjs';
import { switchMap, takeWhile } from 'rxjs/operators';

import { ApiService, LogMealRequest, LogMealResponse } from '../../services/api.service';
import { MealPhotoUploadComponent } from '../../meal-photo-upload/meal-photo-upload';
import { LocalMealReviewResult } from '../../meal-photo-upload/meal-photo-upload.types';

@Component({
  selector: 'app-meal-form',
  standalone: true,
  imports: [CommonModule, FormsModule, MealPhotoUploadComponent],
  templateUrl: './meal-form.html',
  styleUrls: ['./meal-form.css'],
})
export class MealFormComponent implements OnDestroy {
  @Input() userId: string | number = '1';
  @Output() saved = new EventEmitter<LogMealResponse>();
  @ViewChild('photoUpload') private photoUpload?: MealPhotoUploadComponent;

  title = '';
  mealType = 'breakfast';
  eatenAt: string = this.nowLocalIso();
  notes = '';
  healthScore = 7;

  isSubmitting = false;
  isWaitingForAi = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;
  aiMessage: string | null = null;
  photoUrl: string | null = null;
  photoCaption = '';

  private pollingSub?: Subscription;

  readonly mealTypes = [
    { value: 'breakfast', label: '🌅 Śniadanie' },
    { value: 'lunch', label: '☀️ Obiad' },
    { value: 'dinner', label: '🌙 Kolacja' },
    { value: 'snack', label: '🍎 Przekąska' },
    { value: 'other', label: '🍽️ Inne' },
  ];

  constructor(private api: ApiService) {}

  ngOnDestroy(): void {
    this.pollingSub?.unsubscribe();
  }

  onMealPhotoUploaded(result: LocalMealReviewResult): void {
    const review = result.meal_review;
    const caption = review.caption.trim();

    this.photoUrl = review.url;
    this.photoCaption = caption;
    this.successMessage = 'Zdjęcie dodane. Po zapisie posiłku AI ustawi ocenę na skali.';
    this.aiMessage = null;

    if (!this.title.trim()) {
      this.title = caption || 'Posiłek ze zdjęcia';
    }

    if (caption && !this.notes.trim()) {
      this.notes = caption;
    }
  }

  async submit(): Promise<void> {
    this.errorMessage = null;
    this.aiMessage = null;

    if (!this.title.trim()) {
      this.errorMessage = 'Podaj nazwę posiłku.';
      return;
    }

    this.isSubmitting = true;

    if (!this.photoUrl && this.photoUpload?.hasSelectedImage) {
      this.successMessage = 'Wysyłanie zdjęcia...';
      const uploadResult = await this.photoUpload.uploadSelectedImage();

      if (!uploadResult) {
        this.isSubmitting = false;
        this.successMessage = null;
        this.errorMessage = 'Nie udało się wysłać zdjęcia. Spróbuj ponownie.';
        return;
      }
    }

    const payload: LogMealRequest = {
      title: this.title.trim(),
      meal_type: this.mealType,
      eaten_at: new Date(this.eatenAt).toISOString(),
      notes: this.notes,
      photo_url: this.photoUrl ?? undefined,
      health_score: this.photoUrl ? undefined : this.healthScore,
    };

    this.api.logMeal(payload).subscribe({
      next: (response) => {
        this.isSubmitting = false;
        this.successMessage = response.message ?? 'Posiłek zapisany!';
        this.saved.emit(response);

        if (this.photoUrl && response.meal_id) {
          this.startMealStatusPolling(response.meal_id);
          return;
        }

        this.resetForm();
        setTimeout(() => { this.successMessage = null; }, 3000);
      },
      error: (err) => {
        this.isSubmitting = false;
        this.errorMessage = err?.error?.detail ?? 'Blad zapisu. Sprobuj ponownie.';
      },
    });
  }

  private startMealStatusPolling(mealId: number): void {
    this.pollingSub?.unsubscribe();
    this.isWaitingForAi = true;
    this.aiMessage = 'AI analizuje zdjęcie posiłku...';

    this.pollingSub = interval(2500).pipe(
      switchMap(() => this.api.getMealStatus(mealId)),
      takeWhile((mealStatus) => mealStatus.status === 'pending', true),
    ).subscribe({
      next: (mealStatus) => {
        if (mealStatus.status === 'pending') {
          this.aiMessage = 'AI analizuje zdjęcie posiłku...';
          return;
        }

        this.isWaitingForAi = false;

        if (mealStatus.status === 'completed' && mealStatus.health_score !== null) {
          this.healthScore = mealStatus.health_score;
          this.successMessage = `AI oceniło posiłek na ${mealStatus.health_score}/10.`;
          this.aiMessage = mealStatus.exp_granted > 0
            ? `Przyznano ${mealStatus.exp_granted} XP.`
            : null;
          this.saved.emit({
            status: 'completed',
            meal_id: mealStatus.meal_id,
            exp_granted: mealStatus.exp_granted,
            rewards: [],
          });
          return;
        }

        this.aiMessage = null;
        this.errorMessage = 'Nie udało się automatycznie ocenić zdjęcia. Ustaw ocenę ręcznie.';
      },
      error: () => {
        this.isWaitingForAi = false;
        this.aiMessage = null;
        this.errorMessage = 'Nie udało się pobrać wyniku analizy AI.';
      },
    });
  }

  private resetForm(): void {
    this.title = '';
    this.mealType = 'breakfast';
    this.eatenAt = this.nowLocalIso();
    this.notes = '';
    this.healthScore = 7;
    this.photoUrl = null;
    this.photoCaption = '';
    this.aiMessage = null;
    this.isWaitingForAi = false;
  }

  private nowLocalIso(): string {
    const now = new Date();
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
    return now.toISOString().slice(0, 16);
  }
}
