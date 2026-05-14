import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './login.html'
})
export class LoginComponent {
  email = '';
  password = '';
  errorMessage = '';
  isLoading = false;

  constructor(private router: Router) { }

  goToRegister() {
    this.router.navigate(['/register']);
  }

  onLogin() {
    this.isLoading = true;
    this.errorMessage = '';

    // TODO: zastąpić prawdziwym backendem
    of({ access_token: 'mock-token-123' }).pipe(delay(1000)).subscribe({
      next: (response: any) => {
        localStorage.setItem('token', response.access_token);
        this.router.navigate(['/dashboard']);
      }
    });
  }
}
