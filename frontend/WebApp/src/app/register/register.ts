import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';

import { environment } from '../../environments/environment';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './register.html'
})
export class RegisterComponent {
  email = '';
  password = '';
  confirmPassword = '';
  errorMessage = '';
  isLoading = false;

  constructor(private http: HttpClient, private router: Router) { }

  onRegister() {
    this.errorMessage = '';

    if (this.password !== this.confirmPassword) {
      this.errorMessage = "Passwords don't match.";
      return;
    }

    if (this.password.length < 8) {
      this.errorMessage = 'Password has to have at least 8 characters.';
      return;
    }

    this.isLoading = true;

    this.http.post(`${environment.apiUrl}/api/register`, {
      email: this.email,
      password: this.password
    }).subscribe({
      next: () => {
        this.router.navigate(['/login']);
      },
      error: (err: any) => {
        this.isLoading = false;
        if (err.status === 409) {
          this.errorMessage = 'This email is already in use.';
        } else {
          this.errorMessage = 'Server Error. Try again';
        }
      }
    });
  }

  goToLogin() {
    this.router.navigate(['/login']);
  }
}
