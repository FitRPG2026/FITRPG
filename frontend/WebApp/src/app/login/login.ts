import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../auth';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './login.html'
})
export class Login {
  email = '';
  password = '';
  errorMessage = '';
  isLoading = false;

  constructor(
    private router: Router,
    private authService: AuthService
  ) { }

  goToRegister() {
    this.router.navigate(['/register']);
  }

  onLogin() {
    this.isLoading = true;
    this.errorMessage = '';

    this.authService.login(this.email, this.password).subscribe({
      next: () => {
        console.log("Token zapisany! Próbuję przejść na dashboard...");
        this.isLoading = false;
        this.router.navigate(['/dashboard']).then (success => {
          console.log("Czy nawigacja się udała?", success);
        });
      },
      error: (err: any) => {
        this.isLoading = false;
        if (err.status === 401) {
          this.errorMessage = 'Nieprawidłowy adres e-mail lub hasło.';
        } else {
          this.errorMessage = 'Błąd serwera. Spróbuj ponownie.';
        }
      }
    });
  }
}
