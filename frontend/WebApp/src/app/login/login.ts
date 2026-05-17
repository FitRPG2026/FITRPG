import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { AuthService } from '../auth'; 
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

  constructor(private router: Router, private authService: AuthService, private http: HttpClient) { }

  goToRegister() {
    this.router.navigate(['/register']);
  }

  onLogin() {
    this.isLoading = true;
    this.errorMessage = '';

    /*
    this.authService.login(this.email, this.password).subscribe({
      next: (response: any) => {
        this.isLoading = false;
        localStorage.setItem('token', response.access_token);
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.isLoading = false;
        this.errorMessage = 'Błąd logowania. Sprawdź e-mail i hasło.';
        console.error('Błąd logowania:', err);
      }
    });
    */

    //mock logowania
    of({ access_token: 'testowy-token-bez-bazy-123' }).pipe(delay(500)).subscribe({
      next: (response: any) => {
        this.isLoading = false;
        
        localStorage.setItem('token', response.access_token);
        
        this.http.get('http://localhost:8000/api/test').subscribe({
            next: () => console.log('Wysłano test!'),
            error: () => console.log('Zapytanie wysłane!')
        });

        this.router.navigate(['/dashboard']);
      }
    });
  }
}
