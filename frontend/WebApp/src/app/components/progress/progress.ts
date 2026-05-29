import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService, WorkoutData } from '../../services/api.service';

interface Workout {
  workout_type: string;
  title: string;
  performed_at: string; // ISO String z backendu
  duration_min: number;
  health_score: number;
  notes?: string;
  exercises_json?: string;
  exp_amount: number;
  activity_category?: string;
  activity_name?: string;
}

interface CalendarDay {
  date: Date;
  isCurrentMonth: boolean;
  hasWorkout: boolean;
  isToday: boolean;
}

@Component({
  selector: 'app-progress',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './progress.html',
  styleUrls: ['./progress.css'] // <-- NAPRAWIONE: Jedna kropka przed css!
})
export class ProgressComponent implements OnInit {
  // Tutaj podepnij serwis pobierający dane z GET /workouts
  workoutsList: WorkoutData[] = []; // Używamy nowego interfejsu z serwisu
  selectedWorkouts: WorkoutData[] = [];
  selectedDate: Date = new Date();
  constructor(private api: ApiService) {}
  calendarDays: CalendarDay[] = [];
  currentMonth: Date = new Date();
  
  weekDays: string[] = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  months: string[] = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
  ];

  ngOnInit(): void {
    this.api.getWorkouts().subscribe({
      next: (workoutsFromDb: WorkoutData[]) => { // Dodaliśmy jawny typ : WorkoutData[]
        console.log('Dane z bazy:', workoutsFromDb);
        this.workoutsList = workoutsFromDb;
        this.generateCalendar();
        this.selectDate(this.selectedDate);
      },
      error: (err: any) => { // Dodaliśmy jawny typ : any
        console.error('Nie udało się pobrać historii treningów', err);
      }
    });
  }

  generateCalendar(): void {
    this.calendarDays = [];
    const year = this.currentMonth.getFullYear();
    const month = this.currentMonth.getMonth();

    const firstDayOfMonth = new Date(year, month, 1);
    const lastDayOfMonth = new Date(year, month + 1, 0);

    // Dopasowanie do poniedziałku jako pierwszego dnia tygodnia (0 - Nd, 1 - Pn...)
    let startDayOfWeek = firstDayOfMonth.getDay() - 1;
    if (startDayOfWeek === -1) startDayOfWeek = 6;

    // Dni z poprzedniego miesiąca
    for (let i = startDayOfWeek; i > 0; i--) {
      const d = new Date(year, month, 1 - i);
      this.calendarDays.push(this.createCalendarDayObj(d, false));
    }

    // Dni z bieżącego miesiąca
    for (let i = 1; i <= lastDayOfMonth.getDate(); i++) {
      const d = new Date(year, month, i);
      this.calendarDays.push(this.createCalendarDayObj(d, true));
    }

    // Dni z następnego miesiąca do pełnych tygodni (wypełnienie siatki)
    const totalSlots = 42; // 6 tygodni x 7 dni
    const nextMonthDaysNeeded = totalSlots - this.calendarDays.length;
    for (let i = 1; i <= nextMonthDaysNeeded; i++) {
      const d = new Date(year, month + 1, i);
      this.calendarDays.push(this.createCalendarDayObj(d, false));
    }
  }

  private createCalendarDayObj(date: Date, isCurrentMonth: boolean): CalendarDay {
    const today = new Date();
    const isToday = date.getDate() === today.getDate() &&
                    date.getMonth() === today.getMonth() &&
                    date.getFullYear() === today.getFullYear();

    const hasWorkout = this.workoutsList.some(w => {
      const wDate = new Date(w.performed_at);
      return wDate.getDate() === date.getDate() &&
             wDate.getMonth() === date.getMonth() &&
             wDate.getFullYear() === date.getFullYear();
    });

    return { date, isCurrentMonth, hasWorkout, isToday };
  }

  prevMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() - 1, 1);
    this.generateCalendar();
  }

  nextMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + 1, 1);
    this.generateCalendar();
  }

  selectDate(dateInput: Date | string): void {
    const date = typeof dateInput === 'string' ? new Date(dateInput) : dateInput;
    
    this.selectedDate = date;
    this.selectedWorkouts = this.workoutsList.filter(w => {
      const wDate = new Date(w.performed_at);
      return wDate.getDate() === date.getDate() &&
             wDate.getMonth() === date.getMonth() &&
             wDate.getFullYear() === date.getFullYear();
    });
  }

  isSameDate(date1: Date, date2: Date): boolean {
    return date1.getDate() === date2.getDate() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getFullYear() === date2.getFullYear();
  }

  parseExercises(jsonStr?: string): any[] {
    if (!jsonStr) return [];
    try {
      return JSON.parse(jsonStr);
    } catch (e) {
      return [];
    }
  }
}
