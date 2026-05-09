import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { UserProfile } from './interfaces/UserProfile';
import { Config } from '../config';

@Injectable({
  providedIn: 'root',
})
export class ProfileService {

  userProfile: UserProfile | null = null;

  constructor(private http: HttpClient) {}

  async getUserContent(): Promise<void> {
    const link = Config.address + 'api/ProfileEndpoint/GetUserInfo';
    try {
      this.userProfile = await firstValueFrom(
        this.http.get<UserProfile>(link)
      );
    } catch {
      // silently fail — profile will remain null
    }
  }
}
