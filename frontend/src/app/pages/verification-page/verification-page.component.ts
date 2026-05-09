import { Component } from '@angular/core';
import {InputComponent} from "../../components/common/input/input.component";
import { HttpClient } from "@angular/common/http";
import {Config} from "../../config";
import {Router} from "@angular/router";
import {ButtonComponent} from "../../components/common/button/button.component";
import {FormsModule} from "@angular/forms";
import {TitleComponent} from "../../components/common/title/title.component";
import {ProfileService} from "../../services/ProfileService";

@Component({
  selector: 'app-verification-page',
  standalone: true,
  imports: [
    InputComponent,
    ButtonComponent,
    FormsModule,
    TitleComponent
  ],
  templateUrl: './verification-page.component.html',
  styleUrl: './verification-page.component.css'
})
export class VerificationPageComponent {
  token: string = "";

  constructor(public router: Router, public profileService: ProfileService, private http: HttpClient) {
    this.profileService.getUserContent();
  }
  verifyUser() {
    const url = Config.address + 'Verification';
    this.http.post(url, { token: this.token, userId: this.profileService.userProfile?.id })
      .subscribe({
        next: () => this.router.navigate(['/home-page']),
        error: () => alert('Verification Error!'),
      });
  }
}
