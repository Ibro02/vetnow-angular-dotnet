import { Component } from '@angular/core';
import {InputComponent} from "../../components/common/input/input.component";
import axios from "axios";
import {Config} from "../../config";
import {routes} from "../../app.routes";
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

  constructor(public router: Router, public profileService: ProfileService) {
    this.profileService.getUserContent();
  }
  verifyUser() {
    let url = Config.address + "Verification"
    axios.post(url, {token: this.token, userId: this.profileService.userProfile?.id}).then(value => {
      this.router.navigate(['/home-page']);
    }).catch(()=>alert("Verification Error!"));
    //implement API /Verification
  }
}
