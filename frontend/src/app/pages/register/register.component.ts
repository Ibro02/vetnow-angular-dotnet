import { Component, OnInit } from '@angular/core';
import { OtherSignUpMethodsComponent } from "../../components/other-sign-up-methods/other-sign-up-methods.component";
import { SignInInputComponent } from "../../components/common/sign-in-input/sign-in-input.component";
import { MyAuthService } from '../../services/MyAuth';
import axios from "axios";
import {Router, RouterLink} from "@angular/router";
import { ToasterService } from '../../services/toaster.service';
import { shake, fadeIn } from '../../animations/shared.animations';

@Component({
    selector: 'app-register',
    standalone: true,
    templateUrl: './register.component.html',
    styleUrl: './register.component.css',
    imports: [
        OtherSignUpMethodsComponent,
        SignInInputComponent
    ],
    animations: [shake, fadeIn],
})
export class RegisterComponent implements OnInit{
    constructor(public router:Router,private myAuthService:MyAuthService, private toaster: ToasterService) {

    }
ngOnInit(): void {
}
public newUser = {
    Email : "",
    Username : "",
    Password : "",
}

emailRegex = new RegExp('^[\\w\\-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
passwordRegex = new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^\\da-zA-Z]).{8,128}$');
usernameRegex = new RegExp('^[a-zA-Z0-9_\\-]{5,30}$');
isError = false;

 register = () => {
    const emailValid = this.emailRegex.test(this.newUser.Email);
    const passwordValid = this.passwordRegex.test(this.newUser.Password);
    const usernameValid = this.usernameRegex.test(this.newUser.Username);

    if (!emailValid) {
      this.isError = true;
      this.toaster.error('Validation Error', 'Email format is invalid.');
      return;
    }
    if (!usernameValid) {
      this.isError = true;
      this.toaster.error('Validation Error', 'Username must be 5–30 characters (letters, digits, _ or -).');
      return;
    }
    if (!passwordValid) {
      this.isError = true;
      this.toaster.error('Validation Error', 'Password must be 8–128 characters with uppercase, lowercase, digit, and special character.');
      return;
    }

    if (true){
        let link = "https://localhost:44308/api/Person/Add";
        axios.post(link, this.newUser,{headers:{
            'my-auth-token': (window.sessionStorage.getItem('my-auth-token'))
        }})
        .then(x=> {
            // window.sessionStorage.setItem('my-auth-token',x.data)
            // this.myAuthService.loginValue.password = this.newUser.Password;
            // this.myAuthService.loginValue.usernameOrEmail = this.newUser.Email;
          this.router.navigate(["/"]);
          this.toaster.success('Success!', 'You have been registered successfully! Redirecting to login page.');
        })
        .catch(
            err=>{
                console.log(err);
                if(!err.response.data.errors)
                this.toaster.error("Error", err.response.data);
            else{
                for(let i in err?.response.data?.errors){
                    this.toaster.error("Error",err?.response.data?.errors[i][0])
                }
            }
        }

        );
    }
    else{
        this.isError=true;
        this.toaster.error("Error","Incorrect user name or email entry")
    }
 }
 handleValueChanged($event:string, obj:string) {
    //@ts-ignore
    this.newUser[obj] = $event;
    console.log($event);
  }

}
