import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NotificationService, Toast } from '../../services/notification.service';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './toast-container.html',
  styleUrls: ['./toast-container.css'],
})
export class ToastContainerComponent {
  private notificationService = inject(NotificationService);
  toasts$ = this.notificationService.toasts$;

  dismiss(id: number): void {
    this.notificationService.dismiss(id);
  }

  trackById(_: number, toast: Toast): number {
    return toast.id;
  }
}
