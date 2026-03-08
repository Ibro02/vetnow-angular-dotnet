import {Component, OnInit, HostListener} from '@angular/core';
import { CommonModule } from '@angular/common';
import {Router, RouterOutlet} from '@angular/router';
import {LoginComponent} from "./pages/login/login.component";
import {NavbarComponent} from "./navbar/navbar.component";
import {ToasterComponent} from "./components/toaster/toaster.component";
import {MyAuthService} from "./services/MyAuth";
import { RegisterComponent } from './pages/register/register.component';
import { VetCardComponent } from './components/group/vet-card/vet-card.component';
@Component({
    selector: 'app-root',
    standalone: true,
    templateUrl: './app.component.html',
    styleUrl: './app.component.css',
    imports: [CommonModule, RouterOutlet, LoginComponent,NavbarComponent, ToasterComponent, VetCardComponent, RegisterComponent]
})



export class AppComponent implements  OnInit{
  title = 'frontend';

  @HostListener('window:keydown', ['$event'])
  handleKeyboardEvent(event: KeyboardEvent) {
    if (event.altKey && event.key === 's') {
      event.preventDefault(); // Stop the browser from doing its own thing
      this.navigateToSettings();
    }
  }

  navigateToSettings(): void {
    this.router.navigate(['settings']);
  }


  constructor(public myAuthToken: MyAuthService,private router:Router) {

  }

  ngOnInit() {


  }

  test(response:any)
  {
    console.log(response);
  }
}
