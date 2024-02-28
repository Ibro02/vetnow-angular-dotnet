import {Routes} from '@angular/router';
import {LoginComponent} from "./pages/login/login.component";
import {HomePageComponent} from "./pages/home-page/home-page.component";
import {AuthorizationGuard} from "../helper/authLogin";
import { RegisterComponent } from './pages/register/register.component';
import { VetStationHomePageComponent } from './components/vet-station-home-page/vet-station-home-page.component';
import { VetStationComponent } from './pages/vet-station/vet-station.component';
import { SettingsComponent } from './pages/settings/settings.component';

export const routes: Routes = [{ path: '', component: LoginComponent},
  { path: 'register', component: RegisterComponent, },
  { path: 'home-page', component: HomePageComponent, canActivate: [AuthorizationGuard] },
  { path: 'home-page/vet-station-home/:id', component: VetStationHomePageComponent, canActivate: [AuthorizationGuard] },
  { path: 'settings', component: SettingsComponent, canActivate: [AuthorizationGuard]},
  { path: 'settings/vet-station', component: VetStationComponent, canActivate: [AuthorizationGuard]}
]

