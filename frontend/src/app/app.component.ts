import {Component, OnInit, HostListener} from '@angular/core';
import { CommonModule } from '@angular/common';
import {NavigationStart, Router, RouterOutlet} from '@angular/router';
import {LoginComponent} from "./pages/login/login.component";
import {NavbarComponent} from "./navbar/navbar.component";
import {ToasterComponent} from "./components/toaster/toaster.component";
import {MyAuthService} from "./services/MyAuth";
import { RegisterComponent } from './pages/register/register.component';
import { VetCardComponent } from './components/group/vet-card/vet-card.component';
import { routeFadeAnimation } from './animations/route.animations';

@Component({
    selector: 'app-root',
    standalone: true,
    templateUrl: './app.component.html',
    styleUrl: './app.component.css',
    animations: [routeFadeAnimation],
    imports: [CommonModule, RouterOutlet, LoginComponent, NavbarComponent, ToasterComponent, VetCardComponent, RegisterComponent]
})
export class AppComponent implements OnInit {
  title = 'frontend';

  @HostListener('window:keydown', ['$event'])
  handleKeyboardEvent(event: KeyboardEvent) {
    if (event.altKey && event.key === 's') {
      event.preventDefault();
      this.navigateToSettings();
    }
  }

  navigateToSettings(): void {
    this.router.navigate(['settings']);
  }

  constructor(public myAuthToken: MyAuthService, private router: Router) {}

  ngOnInit() {}

  prepareRoute(outlet: RouterOutlet) {
    if (!outlet || !outlet.isActivated) return null;
    return outlet.activatedRouteData?.['animation']
      ?? outlet.activatedRoute?.snapshot?.url?.toString();
  }
}
