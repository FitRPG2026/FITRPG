import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SplashScreen } from './components/splash-screen/splash-screen';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, SplashScreen],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class AppComponent {

  isServerReady = signal(false);

  onServerReady() {
    this.isServerReady.set(true);
  }

 }
