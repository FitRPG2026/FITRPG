import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';

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

  constructor(private http: HttpClient, private router: Router) { }

  goToRegister() {
    this.router.navigate(['/register']);
  }

  onLogin() {
    this.isLoading = true;
    this.errorMessage = '';

    this.http.post('http://localhost:8000/api/login', {
      email: this.email,
      password: this.password
    }).subscribe({
      next: (response: any) => {
        localStorage.setItem('token', response.access_token);
        this.router.navigate(['/dashboard']);
      },
      error: (err: any) => {
        this.isLoading = false;
        if (err.status === 401) {
          this.errorMessage = 'Nieprawidłowy email lub hasło.';
        } else {
          this.errorMessage = 'Błąd serwera. Spróbuj ponownie.';
        }
      }
    });
  }
}
