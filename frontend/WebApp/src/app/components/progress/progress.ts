import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';

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
  styleUrls: ['./progress..css']
})
export class ProgressComponent implements OnInit {
  // Tutaj podepnij serwis pobierający dane z GET /workouts
  workoutsList: Workout[] = []; 
  
  calendarDays: CalendarDay[] = [];
  currentMonth: Date = new Date();
  selectedDate: Date = new Date();
  selectedWorkouts: Workout[] = [];
  
  weekDays: string[] = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  months: string[] = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
  ];

  ngOnInit(): void {
    // Dane demonstracyjne odwzorowujące strukturę z Twojego backendu
    this.workoutsList = [
      {
        title: 'Poranny Rozruch',
        workout_type: 'Strength',
        performed_at: new Date().toISOString(),
        duration_min: 45,
        health_score: 8,
        notes: 'Dobra pompa, progres ciężaru w przysiadach.',
        exp_amount: 150,
        activity_name: 'Trening Siłowy',
        exercises_json: '[{"name": "Przysiad", "sets": 4}]'
      },
      {
        title: 'Bieganie w lesie',
        workout_type: 'Cardio',
        performed_at: new Date(Date.now() - 86400000 * 2).toISOString(), // 2 dni temu
        duration_min: 60,
        health_score: 9,
        notes: 'Świetne tempo, pogoda dopisała.',
        exp_amount: 200,
        activity_name: 'Bieganie'
      }
    ];

    this.generateCalendar();
    this.selectDate(this.selectedDate);
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

  selectDate(date: Date): void {
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
