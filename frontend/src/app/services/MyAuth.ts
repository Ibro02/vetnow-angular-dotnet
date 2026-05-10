import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { LoginRequest } from '../pages/login/LoginRequest';
import { Config } from '../config';
import { UserProfile } from './interfaces/UserProfile';

@Injectable({ providedIn: 'root' })
export class MyAuthService {
  userProfile: UserProfile | null = null;
  rememberMe = false;

  loginValue: LoginRequest = {
    id: 0,
    usernameOrEmail: '',
    password: '',
  };

  token: string | null = null;

  constructor(
    public router: Router,
    private http: HttpClient,
  ) {
    // Initialize token from storage on service creation
    this.token = this.getToken();
  }

  /** Synchronously reads the token from storage. */
  getToken(): string | null {
    return (
      window.localStorage.getItem('my-auth-token') ??
      window.sessionStorage.getItem('my-auth-token')
    );
  }

  /** Stores the token in the appropriate storage based on rememberMe. */
  private storeToken(token: string): void {
    if (this.rememberMe) {
      window.localStorage.setItem('my-auth-token', token);
    } else {
      window.sessionStorage.setItem('my-auth-token', token);
    }
    this.token = token;
  }

  IsLogged(): boolean {
    this.token = this.getToken();
    if (this.token != null) return this.token !== ' ';
    return false;
  }

  async IsVerified(): Promise<boolean> {
    // Re-read the token from storage so we use the freshly stored one after login
    this.token = this.getToken();

    const link = Config.address + 'api/ProfileEndpoint/GetUserInfo';
    try {
      this.userProfile = await firstValueFrom(
        this.http.get<UserProfile>(link)
      );
    } catch {
      // silently fail — user will be treated as unverified
    }

    return this.userProfile?.verified ?? false;
  }

  LogOut(): void {
    // Read token BEFORE removing it so we can send the DELETE request
    const token = this.getToken();

    window.localStorage.removeItem('my-auth-token');
    window.sessionStorage.removeItem('my-auth-token');
    this.token = null;

    if (token) {
      const link = Config.address + 'api/LoginAuth/Delete';
      // Send the DELETE with explicit header since we just cleared storage
      // (the interceptor would read null from storage at this point)
      this.http
        .delete(link, { headers: { 'my-auth-token': token }, responseType: 'text' })
        .subscribe({ error: () => {} });
    }

    this.router.navigate(['/']);
  }

  /**
   * Logs in with the current loginValue credentials.
   * Stores the returned token and returns it.
   */
  async getAuthorizationToken(): Promise<string> {
    const link = Config.address + 'api/LoginAuth/Post';
    try {
      const newToken = await firstValueFrom(
        this.http.post(link, this.loginValue, { responseType: 'text' })
      );
      this.storeToken(newToken);
      return newToken;
    } catch {
      return ' ';
    }
  }

  /**
   * Sends a Google ID token to the backend, which validates it with Google
   * and returns the app's own session token (login or auto-register).
   */
  async loginWithGoogle(googleIdToken: string): Promise<boolean> {
    const link = Config.address + 'api/GoogleAuth/Login';
    try {
      const newToken = await firstValueFrom(
        this.http.post(link, { idToken: googleIdToken }, { responseType: 'text' })
      );
      // Google logins are always "remembered"
      window.localStorage.setItem('my-auth-token', newToken);
      this.token = newToken;
      return true;
    } catch {
      return false;
    }
  }

  // ─── Role helpers ───

  /** Permission level: 1=User, 2=Employee, 3=MainVet, 4=Admin */
  getPermissionLevel(): number {
    return this.userProfile?.permissionLevel ?? 1;
  }

  isAtLeastEmployee(): boolean {
    return this.getPermissionLevel() >= 2;
  }

  isAtLeastMainVet(): boolean {
    return this.getPermissionLevel() >= 3;
  }

  isAdminUser(): boolean {
    return this.getPermissionLevel() >= 4;
  }
}
