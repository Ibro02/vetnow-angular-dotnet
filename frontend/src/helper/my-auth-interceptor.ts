import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

/**
 * Functional HTTP interceptor that:
 * 1. Reads the auth token synchronously from storage
 * 2. Attaches it as the 'my-auth-token' header
 * 3. Redirects to login on 401 responses
 */
export const myAuthInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);

  const token =
    window.localStorage.getItem('my-auth-token') ??
    window.sessionStorage.getItem('my-auth-token');

  const authReq = token
    ? req.clone({ setHeaders: { 'my-auth-token': token } })
    : req;

  return next(authReq).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        // Purge stale token so IsLogged() returns false on the next tick.
        // Without this, callers like NavbarComponent.loadSchedule() see a
        // truthy token, re-issue GetUserInfo, get another 401, and loop.
        window.localStorage.removeItem('my-auth-token');
        window.sessionStorage.removeItem('my-auth-token');
        if (router.url !== '/') {
          router.navigateByUrl('/');
        }
      }
      return throwError(() => err);
    })
  );
};
