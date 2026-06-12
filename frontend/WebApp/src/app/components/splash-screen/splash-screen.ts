import { Component, OnInit, OnDestroy, inject, signal, output } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { timer, switchMap, catchError, of, filter, take, Subscription, forkJoin } from 'rxjs';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-splash-screen',
  standalone: true,
  templateUrl: './splash-screen.html',
  styleUrl: './splash-screen.css'
})
export class SplashScreen implements OnInit, OnDestroy {
  private http = inject(HttpClient);
  private subs = new Subscription();

  serverReady = output<void>();
  
  currentText = signal('Nawiązywanie połączenia z serwerem bazowym...');

  private loadingTexts = [
    "Wczytywanie statystyk...",
    "Parzenie kawy dla sztucznej inteligencji...",
    "Trwa to dłużej niż zwykle, rozgrzewamy silniki chmurowe..."
  ];

  ngOnInit() {
    this.subs.add(
      timer(10000, 10000).subscribe((val) => {
        const index = val % this.loadingTexts.length;
        this.currentText.set(this.loadingTexts[index]);
      })
    );

    const minimumTime$ = timer(1500);

    const serverPing$ = timer(0, 5000).pipe(
      switchMap(() => this.http.get(`${environment.apiUrl}/api/health`, { responseType: 'text' }).pipe(
        catchError(() => of(null))
      )),
      filter(response => response !== null),
      take(1)
    );

    this.subs.add(
      forkJoin([minimumTime$, serverPing$]).subscribe(() => {
        this.serverReady.emit();
      })
    );
  }

  ngOnDestroy() {
    this.subs.unsubscribe();
  }
}