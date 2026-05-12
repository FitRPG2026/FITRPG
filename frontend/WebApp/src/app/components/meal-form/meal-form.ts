import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService, LogMealRequest, LogMealResponse } from '../../services/api.service';

@Component({
  selector: 'app-meal-form',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './meal-form.html',
  styleUrls: ['./meal-form.css'],
})
export class MealFormComponent {
  @Output() saved = new EventEmitter<LogMealResponse>();

  title = '';
  mealType = 'breakfast';
  eatenAt: string = this.nowLocalIso();
  notes = '';
  healthScore = 7;

  isSubmitting = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;

  readonly mealTypes = [
    { value: 'breakfast', label: '🌅 Śniadanie' },
    { value: 'lunch',     label: '☀️ Obiad' },
    { value: 'dinner',    label: '🌙 Kolacja' },
    { value: 'snack',     label: '🍎 Przekąska' },
    { value: 'other',     label: '🍽️ Inne' },
  ];

  constructor(private api: ApiService) {}

  submit(): void {
    this.errorMessage = null;
    if (!this.title.trim()) {
      this.errorMessage = 'Podaj nazwę posiłku.';
      return;
    }

    const payload: LogMealRequest = {
      title: this.title.trim(),
      meal_type: this.mealType,
      eaten_at: new Date(this.eatenAt).toISOString(),
      notes: this.notes,
      health_score: this.healthScore,
    };

    this.isSubmitting = true;
    this.api.logMeal(payload).subscribe({
      next: (response) => {
        this.isSubmitting = false;
        this.successMessage = 'Posiłek zapisany!';
        this.saved.emit(response);
        this.resetForm();
        setTimeout(() => { this.successMessage = null; }, 3000);
      },
      error: (err) => {
        this.isSubmitting = false;
        this.errorMessage = err?.error?.detail ?? 'Błąd zapisu. Spróbuj ponownie.';
      },
    });
  }

  private resetForm(): void {
    this.title = '';
    this.mealType = 'breakfast';
    this.eatenAt = this.nowLocalIso();
    this.notes = '';
    this.healthScore = 7;
  }

  private nowLocalIso(): string {
    const now = new Date();
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
    return now.toISOString().slice(0, 16);
  }
}
