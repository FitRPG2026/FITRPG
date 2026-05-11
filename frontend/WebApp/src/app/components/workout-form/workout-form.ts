import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService, LogWorkoutRequest, LogWorkoutResponse } from '../../services/api.service';

interface ExerciseRow {
  exercise_name: string;
  exercise_order: number;
  exercise_group: string;
  sets: number | null;
  reps: number | null;
  weight_kg: number | null;
  notes: string;
}

interface CategoryOption {
  key: string;
  label: string;
  activity_category: string;
  workout_type: string;
}

@Component({
  selector: 'app-workout-form',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './workout-form.html',
  styleUrls: ['./workout-form.css'],
})
export class WorkoutFormComponent {
  @Output() saved = new EventEmitter<LogWorkoutResponse>();

  title = '';
  categoryKey = 'gym';
  durationMin = 120;
  performedAt: string = this.nowLocalIso();
  notes = '';
  exercises: ExerciseRow[] = [];

  isSubmitting = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;

  readonly categories: CategoryOption[] = [
    { key: 'gym',     label: 'Siłownia',        activity_category: 'gym',     workout_type: 'strength' },
    { key: 'sport',   label: 'Sport',             activity_category: 'sport',   workout_type: 'sport'    },
    { key: 'cardio',  label: 'Bieganie / Cardio', activity_category: 'general', workout_type: 'cardio'   },
    { key: 'general', label: 'Ogólne',            activity_category: 'general', workout_type: 'other'    },
  ];

  readonly exerciseGroups = [
    { value: 'chest',               label: 'Klatka piersiowa' },
    { value: 'back',                label: 'Plecy' },
    { value: 'legs',                label: 'Nogi' },
    { value: 'glutes',              label: 'Pośladki' },
    { value: 'shoulders',           label: 'Barki' },
    { value: 'biceps',              label: 'Biceps' },
    { value: 'triceps',             label: 'Triceps' },
    { value: 'calves',              label: 'Łydki' },
    { value: 'core',                label: 'Core' },
    { value: 'cardio_conditioning', label: 'Cardio / Kondycja' },
    { value: 'calisthenics',        label: 'Kalistenika' },
    { value: 'other',               label: 'Inne' },
  ];

  constructor(private api: ApiService) {}

  get isGym(): boolean {
    return this.categoryKey === 'gym';
  }

  private get selectedCat(): CategoryOption {
    return this.categories.find(c => c.key === this.categoryKey) ?? this.categories[0];
  }

  onCategoryChange(): void {
    if (!this.isGym) this.exercises = [];
  }

  addExercise(): void {
    this.exercises.push({
      exercise_name: '',
      exercise_order: this.exercises.length + 1,
      exercise_group: 'other',
      sets: null,
      reps: null,
      weight_kg: null,
      notes: '',
    });
  }

  removeExercise(index: number): void {
    this.exercises.splice(index, 1);
    this.exercises.forEach((e, i) => (e.exercise_order = i + 1));
  }

  submit(): void {
    this.errorMessage = null;
    if (!this.title.trim()) {
      this.errorMessage = 'Podaj nazwę treningu.';
      return;
    }
    if (this.durationMin < 1) {
      this.errorMessage = 'Czas trwania musi być większy od 0.';
      return;
    }

    const cat = this.selectedCat;
    const payload: LogWorkoutRequest = {
      title: this.title.trim(),
      workout_type: cat.workout_type,
      activity_category: cat.activity_category,
      duration_min: this.durationMin,
      performed_at: new Date(this.performedAt).toISOString(),
      notes: this.notes,
      exercises: this.isGym ? this.exercises.filter(e => e.exercise_name.trim()) : [],
    };

    this.isSubmitting = true;
    this.api.logWorkout(payload).subscribe({
      next: (response) => {
        this.isSubmitting = false;
        this.successMessage = 'Trening zapisany!';
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
    this.categoryKey = 'gym';
    this.durationMin = 120;
    this.performedAt = this.nowLocalIso();
    this.notes = '';
    this.exercises = [];
  }

  private nowLocalIso(): string {
    const now = new Date();
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
    return now.toISOString().slice(0, 16);
  }
}
