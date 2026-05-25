import { Routes } from '@angular/router';
import { LoginComponent } from './login/login';
import { RegisterComponent } from './register/register';
import { DashboardComponent } from './dashboard/dashboard';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'dashboard', component: DashboardComponent },
  {
    path: 'meal-upload',
    loadComponent: () => import('./meal-photo-upload/meal-photo-upload')
      .then((m) => m.MealPhotoUploadComponent),
  },
];



// import { Routes } from '@angular/router';
// import { LoginComponent } from './login/login';
// import { RegisterComponent } from './register/register';
// import { DashboardComponent } from './dashboard/dashboard';

// export const routes: Routes = [
//   { path: '', redirectTo: 'login', pathMatch: 'full' },
//   { path: 'login', component: LoginComponent },
//   { path: 'register', component: RegisterComponent },
//   { path: 'dashboard', component: DashboardComponent },
//   {
//     path: 'meal-upload',
//     loadComponent: () => import('./meal-photo-upload/meal-photo-upload')
//       .then((m) => m.MealPhotoUploadComponent),
//   },
// ];


// import { Routes } from '@angular/router';
// import { LoginComponent } from './login/login';
// import { RegisterComponent } from './register/register';
// import { DashboardComponent } from './dashboard/dashboard';

// export const routes: Routes = [
//   { path: '', redirectTo: 'login', pathMatch: 'full' },
//   { path: 'login', component: LoginComponent },
//   { path: 'register', component: RegisterComponent },
//   { path: 'dashboard', component: DashboardComponent },
//   {
//     path: 'meal-upload',
//     loadComponent: () => import('./meal-photo-upload/meal-photo-upload')
//       .then((m) => m.MealPhotoUploadComponent),
//   },
//   {
//     path: 'meal-form',
//     loadComponent: () => import('./components/meal-form/meal-form')
//       .then((m) => m.MealFormComponent),
//   },
//   {
//     path: 'workout-form',
//     loadComponent: () => import('./components/workout-form/workout-form')
//       .then((m) => m.WorkoutFormComponent),
//   },
// ];
