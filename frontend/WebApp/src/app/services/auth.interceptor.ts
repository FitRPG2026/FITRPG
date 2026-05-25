import { HttpInterceptorFn } from '@angular/common/http';
import { inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  // Wstrzykujemy identyfikator platformy, żeby sprawdzić, gdzie się znajdujemy
  const platformId = inject(PLATFORM_ID);
  
  // Sięgamy po token tylko, jeśli jesteśmy w przeglądarce
  if (isPlatformBrowser(platformId)) {
    const token = localStorage.getItem('jwt_token');
    
    if (token) {
      const authReq = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
      return next(authReq);
    }
  }

  // Puszczamy request dalej bez modyfikacji
  return next(req);
};