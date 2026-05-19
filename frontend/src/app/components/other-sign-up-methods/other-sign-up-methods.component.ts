import {Component, Input, OnInit, NgZone, AfterViewInit, ElementRef} from '@angular/core';
import {faApple, faFacebook, faGoogle, faMicrosoft} from "@fortawesome/free-brands-svg-icons";
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {NgSwitch, NgSwitchCase} from "@angular/common";
import {MyAuthService} from "../../services/MyAuth";
import {Router} from "@angular/router";

// Declare the global google namespace injected by the GSI script in index.html
declare const google: any;

// Module-level flag: google.accounts.id.initialize() must run exactly once per
// page lifetime. Without this guard, every remount of this component (e.g.
// navigating login ↔ register) re-initializes GIS and triggers the
// "google.accounts.id.initialize() is called multiple times" console warning.
let googleInitialized = false;

@Component({
  selector: 'app-other-sign-up-methods',
  standalone: true,
  imports: [
    FaIconComponent,
    NgSwitchCase,
    NgSwitch
  ],
  templateUrl: './other-sign-up-methods.component.html',
  styleUrl: './other-sign-up-methods.component.css'
})
export class OtherSignUpMethodsComponent implements OnInit, AfterViewInit {

  constructor(
    public myAuthService: MyAuthService,
    private router: Router,
    private ngZone: NgZone,
    private elementRef: ElementRef
  ) {}

  @Input() isLogin: boolean = false;

  // Icons
  protected readonly faGmail = faGoogle;
  protected readonly faMicrosoft = faMicrosoft;
  protected readonly faFacebook = faFacebook;
  protected readonly faApple = faApple;

  ngOnInit() {}

  ngAfterViewInit() {
    this.renderGoogleButton();
  }

  /**
   * Renders the Google Sign-In button using the Google Identity Services (GIS) library.
   * The callback is handled inside Angular's NgZone so change detection works properly.
   */
  private renderGoogleButton(): void {
    if (typeof google === 'undefined' || !google.accounts) {
      // GSI script hasn't loaded yet — retry after a short delay
      setTimeout(() => this.renderGoogleButton(), 200);
      return;
    }

    if (!googleInitialized) {
      google.accounts.id.initialize({
        client_id: '1032558872733-v9evv1snk6l8es598b637nbo2bg1kqd0.apps.googleusercontent.com',
        callback: (response: any) => this.handleGoogleCallback(response),
        auto_select: false,
        cancel_on_tap_outside: true,
      });
      googleInitialized = true;
    }

    const buttonDiv = this.elementRef.nativeElement.querySelector('#google-signin-btn');
    if (buttonDiv) {
      google.accounts.id.renderButton(buttonDiv, {
        type: 'standard',
        shape: 'pill',
        theme: 'outline',
        text: 'continue_with',
        size: 'large',
        logo_alignment: 'left',
      });
    }
  }

  /**
   * Called by Google after the user selects an account in the popup.
   * Sends the credential (ID token) to our backend for validation.
   */
  private handleGoogleCallback(response: any): void {
    // Run inside NgZone so Angular picks up state changes & navigation
    this.ngZone.run(async () => {
      const idToken: string = response.credential;
      if (!idToken) {
        return; // Google Sign-In did not return a credential
      }

      const success = await this.myAuthService.loginWithGoogle(idToken);
      if (success) {
        if (await this.myAuthService.IsVerified()) {
          this.router.navigate(['home-page']);
        } else {
          this.router.navigate(['verification']);
        }
      }
    });
  }
}
