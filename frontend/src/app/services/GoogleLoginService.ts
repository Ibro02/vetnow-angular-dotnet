/**
 * DEPRECATED — This service used the OAuth2 implicit flow via angular-oauth2-oidc.
 *
 * Google Sign-In is now handled by the `other-sign-up-methods` component using
 * the Google Identity Services (GIS) library and our backend GoogleAuthEndpoint.
 *
 * Kept as an empty stub so that any leftover injections don't break at compile time.
 * Safe to delete once all references are removed.
 */
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class GoogleLoginService {
  // No-op — all Google auth logic is in OtherSignUpMethodsComponent + MyAuthService.loginWithGoogle()
}
