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

 async getUserContent(): Promise<void>
  {
    var link = Config.address + "api/ProfileEndpoint/GetUserInfo/";

    try{
    const response = await axios.get(link + this.myAuthService.token,{headers:{'my-auth-token': this.myAuthService.token}});
    this.userProfile = response?.data;
    } catch (error) {
      console.log(error);
    }
  }



}
