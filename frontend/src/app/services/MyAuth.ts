import {Injectable} from "@angular/core";
import {Router} from "@angular/router";
import axios from "axios";
import {LoginRequest} from "../pages/login/LoginRequest";
import { Config } from "../config";
import {ProfileService} from "./ProfileService";
import {UserProfile} from "./interfaces/UserProfile";
@Injectable({providedIn:"root"})
export class MyAuthService
{
  userProfile:UserProfile|null = null;
  rememberMe = false;

  loginValue: LoginRequest =
    {
      id: 0,
      usernameOrEmail: "",
      password: ""
    };
  constructor(public router:Router) {
  }

  token:string|null = this.rememberMe?window.localStorage.getItem("my-auth-token"):window.sessionStorage.getItem("my-auth-token");
  IsLogged():boolean
  {
    this.token = window.localStorage.getItem("my-auth-token")??window.sessionStorage.getItem("my-auth-token");
    if (this.token != null)
    return this.token != " ";
    else return false;
  }

  async IsVerified()
  {
    var link = Config.address + "api/ProfileEndpoint/GetUserInfo/";
    try{
      const response = await axios.get(link + this.token,{headers:{'my-auth-token': this.token}});
      this.userProfile = response?.data;
    } catch (error) {
      console.log(error);
    }


    return this.userProfile?.verified ?? false;
  }
LogOut():void
{
  window.localStorage.removeItem("my-auth-token");
  window.sessionStorage.removeItem("my-auth-token");

  let link = Config.address + "api/LoginAuth/Delete/"
  axios.delete(link+this.token).catch(x=>console.log(x));

  this.router.navigate(["/"]);
}

  /**
   * Fixed: the old implementation returned BEFORE the axios POST resolved,
   * so the token was never stored from the response. The login component
   * (login.component.ts) already handles its own axios call and stores
   * the token correctly, so this helper is kept for backward-compat but
   * now actually awaits and stores the result.
   */
  async getAuthorizationToken(): Promise<string> {
    let link = Config.address + "api/LoginAuth/Post";
    try {
      const response = await axios.post(link, this.loginValue, {
        headers: { 'my-auth-token': this.token }
      });
      const newToken = response.data;
      // Store the token based on rememberMe preference
      if (this.rememberMe) {
        window.localStorage.setItem('my-auth-token', newToken);
      } else {
        window.sessionStorage.setItem('my-auth-token', newToken);
      }
      this.token = newToken;
      return newToken;
    } catch (err) {
      console.log(err);
      return " ";
    }
  }

  /**
   * Sends a Google ID token to the backend, which validates it with Google
   * and returns the app's own session token (login or auto-register).
   */
  async loginWithGoogle(googleIdToken: string): Promise<boolean> {
    const link = Config.address + "api/GoogleAuth/Login";
    try {
      const response = await axios.post(link, { idToken: googleIdToken });
      const newToken = response.data;
      // Google logins are always "remembered"
      window.localStorage.setItem('my-auth-token', newToken);
      this.token = newToken;
      return true;
    } catch (err) {
      console.log("Google login failed:", err);
      return false;
    }
  }

}
