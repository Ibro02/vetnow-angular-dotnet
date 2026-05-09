import {Component, OnInit} from '@angular/core';
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {NgClass, NgForOf} from "@angular/common";
import {FormsModule} from "@angular/forms";
import {SignInInputComponent} from "../../components/common/sign-in-input/sign-in-input.component";
import {OtherSignUpMethodsComponent} from "../../components/other-sign-up-methods/other-sign-up-methods.component";
import { HttpClient } from "@angular/common/http";
import {Router, RouterLink} from "@angular/router";
import {MyAuthService} from "../../services/MyAuth";
import { Config } from '../../config';
import {ToasterService} from "../../services/toaster.service";
import { shake, fadeIn } from '../../animations/shared.animations';
@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FaIconComponent, NgClass, FormsModule, SignInInputComponent, FormsModule, OtherSignUpMethodsComponent, RouterLink, NgForOf],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
  animations: [shake, fadeIn],
})
export class LoginComponent implements OnInit{

  constructor(private router:Router, private myAuthService:MyAuthService, private toaster:ToasterService, private http: HttpClient) {

  }
async ngOnInit() {
   if (this.myAuthService.IsLogged()) {
     if (await this.myAuthService.IsVerified())
       this.router.navigate(['home-page']);
     else
       this.router.navigate(['verification']);
   }
}

  public usernameOrEmail = "";
  public password = "";

placeholder:any
emailRegex = new RegExp('^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
passwordRegex = new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^\\da-zA-Z]).{8,}$');
checkBox:boolean = false;
token :any;
isError:boolean = false;
  signIn = () => {
    this.myAuthService.loginValue!.usernameOrEmail = this.usernameOrEmail;
    this.myAuthService.loginValue!.password = this.password;
    if (this.usernameOrEmail.trim() && this.password.trim()) {
      const link = Config.address + 'api/LoginAuth/Post';

      this.http.post(link, this.myAuthService.loginValue, { responseType: 'text' })
        .subscribe({
          next: async (token: string) => {
            if (this.myAuthService.rememberMe) {
              window.localStorage.setItem('my-auth-token', token);
            } else {
              window.sessionStorage.setItem('my-auth-token', token);
            }
            this.myAuthService.token = token;

            if (await this.myAuthService.IsVerified())
              this.router.navigate(['home-page']);
            else
              this.router.navigate(['verification']);
          },
          error: () => { this.isError = true; }
        });

      this.isError = false;
    } else {
      this.isError = true;
      this.toaster.error('Error', 'Please enter your username/email and password.');
    }
  }
  handleValueChanged($event:string, obj:string) {
    //@ts-ignore
    this[obj] = $event;
  }

  keepMeSigned()
  {
    this.myAuthService.rememberMe = !this.myAuthService.rememberMe;
    this.checkBox = this.myAuthService.rememberMe;
  }

}

