import { Component, OnInit } from '@angular/core';
import { OtherSignUpMethodsComponent } from "../../components/other-sign-up-methods/other-sign-up-methods.component";
import { SignInInputComponent } from "../../components/common/sign-in-input/sign-in-input.component";
import { MyAuthService } from '../../services/MyAuth';
import axios from "axios";
import {Router, RouterLink} from "@angular/router"; 


@Component({
    selector: 'app-register',
    standalone: true,
    templateUrl: './register.component.html',
    styleUrl: './register.component.css',
    imports: [
        OtherSignUpMethodsComponent,
        SignInInputComponent
    ]
})
export class RegisterComponent implements OnInit{
    constructor(public router:Router,private myAuthService:MyAuthService) {

    }
ngOnInit(): void {    
}
public newUser = {
    Email : "",
    Username : "",
    Password : "",
}
 
emailRegex = new RegExp('^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
passwordRegex = new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^\\da-zA-Z]).{8,}$');
usernameRegex = new RegExp('.{5,}$');
isError = false;

 register = () => {
    console.log(this.newUser);
    if (true){
        let link = "https://localhost:44308/api/Person/Add";
        axios.post(link, this.newUser,{headers:{
            'my-auth-token': (window.sessionStorage.getItem('my-auth-token'))
        }})
        .then(x=> {
            window.sessionStorage.setItem('my-auth-token',x.data)
            this.myAuthService.loginValue.password = this.newUser.Password;
            this.myAuthService.loginValue.usernameOrEmail = this.newUser.Email;
            this.router.navigate(["home-page"]);
        })
        .catch(
            err=>{
                console.log(err);
                if(!err.response.data.errors)
                alert(err.response.data)
            else{
                for(let i in err?.response.data?.errors){
                    alert(err?.response.data?.errors[i][0])
                }
            }
        }

        );
    }
    else{
        this.isError=true;
        window.alert("Pogresan unos korisnickog imena ili emaila")
    }
 }
 handleValueChanged($event:string, obj:string) {
    //@ts-ignore
    this.newUser[obj] = $event;
    console.log($event);
  }
  
}
