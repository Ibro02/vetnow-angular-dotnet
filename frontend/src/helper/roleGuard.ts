import { inject } from "@angular/core";
import { ActivatedRouteSnapshot, CanActivateFn, Router, RouterStateSnapshot } from "@angular/router";
import { MyAuthService } from "../app/services/MyAuth";

/**
 * Factory that creates a role guard requiring a minimum permission level.
 * Usage in routes: canActivate: [roleGuard(2)] // at least Employee
 *
 * Permission levels: 1=User, 2=Employee, 3=MainVet, 4=Admin
 */
export function roleGuard(minLevel: number): CanActivateFn {
  return async (route: ActivatedRouteSnapshot, state: RouterStateSnapshot) => {
    const auth = inject(MyAuthService);
    const router = inject(Router);

    // Ensure user profile is loaded
    if (!auth.userProfile) {
      await auth.IsVerified();
    }

    if (!auth.IsLogged()) {
      router.navigate([''], { queryParams: { povratniUrl: state.url } });
      return false;
    }

    if (auth.getPermissionLevel() >= minLevel) {
      return true;
    }

    // Not enough permissions - redirect to home
    router.navigate(['/home-page']);
    return false;
  };
}
