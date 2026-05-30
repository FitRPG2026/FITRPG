import { Component, OnInit, ChangeDetectorRef } from '@angular/core'; 
import { CommonModule } from '@angular/common'; 
import { ApiService, WorkoutData } from '../../services/api.service';

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
  styleUrls: ['./progress.css'] // POPRAWKA: Zmieniono rozszerzenie z .scss na .css
})
export class ProgressComponent implements OnInit {
  workoutsList: WorkoutData[] = [];
  calendarDays: CalendarDay[] = [];
  currentMonth: Date = new Date();
  selectedDate: Date | null = null;
  selectedWorkouts: WorkoutData[] = [];

  weekDays: string[] = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  months: string[] = [
    'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
  ];

  constructor(
    private apiService: ApiService,
    private cdr: ChangeDetectorRef 
  ) {}

  ngOnInit(): void {
    this.generateCalendar();
    this.loadWorkouts();
  }

  loadWorkouts(): void {
    this.apiService.getWorkouts().subscribe({
      next: (data) => {
        this.workoutsList = [...data];
        this.generateCalendar();
        this.cdr.detectChanges();
      },
      error: (err) => {
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

    let startDayOfWeek = firstDayOfMonth.getDay() - 1;
    if (startDayOfWeek === -1) startDayOfWeek = 6;

    for (let i = startDayOfWeek; i > 0; i--) {
      const d = new Date(year, month, 1 - i);
      this.calendarDays.push(this.createCalendarDayObj(d, false));
    }

    for (let i = 1; i <= lastDayOfMonth.getDate(); i++) {
      const d = new Date(year, month, i);
      this.calendarDays.push(this.createCalendarDayObj(d, true));
    }

    const totalSlots = 42; 
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

  isSameDate(date1: Date, date2: Date | null): boolean {
    if (!date2) return false;
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
