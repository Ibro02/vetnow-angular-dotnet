// google-login.service.ts
import { Injectable } from '@angular/core';
import {UserProfile} from "./interfaces/UserProfile";
import axios from "axios";
import {MyAuthService} from "./MyAuth";
import { Config } from '../config';


@Injectable({
  providedIn: 'root',
})
export class ProfileService {

  userProfile:UserProfile|null = null;

  constructor(private myAuthService:MyAuthService) {
  }

 async getUserContent()
  {
    var link = Config.address + "api/ProfileEndpoint/GetUserInfo/"
    await axios.get(link + this.myAuthService.token,{headers:{'my-auth-token': this.myAuthService.token}}).then(x=> {
      this.userProfile = x.data
    //  console.log(this.userProfile);
    }).catch(x=>console.log(x));
  }



}
