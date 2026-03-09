import {Routes} from '@angular/router';
import {LoginComponent} from "./pages/login/login.component";
import {HomePageComponent} from "./pages/home-page/home-page.component";
import {AuthorizationGuard} from "../helper/authLogin";
import {roleGuard} from "../helper/roleGuard";
import { RegisterComponent } from './pages/register/register.component';
import { VetStationHomePageComponent } from './components/vet-station-home-page/vet-station-home-page.component';
import { VetStationComponent } from './pages/vet-station/vet-station.component';
import { SettingsComponent } from './pages/settings/settings.component';
import { EmployeeListComponent } from './pages/employee-list/employee-list.component';
import {AppointmentPageComponent} from "./pages/appointment-page/appointment-page.component";
import {VerificationPageComponent} from "./pages/verification-page/verification-page.component";
import {ProfileSettingsComponent} from "./pages/profile-settings/profile-settings.component";
import {PetsSettingsComponent} from "./pages/pets-settings/pets-settings.component";
import {MyAppointmentsComponent} from "./pages/my-appointments/my-appointments.component";
import {AdminPanelComponent} from "./pages/admin-panel/admin-panel.component";
import {AvailabilitySettingsComponent} from "./pages/availability-settings/availability-settings.component";

export const routes: Routes = [
  { path: '', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'verification', component: VerificationPageComponent },

  // Any logged-in user
  { path: 'home-page', component: HomePageComponent, canActivate: [AuthorizationGuard] },
  { path: 'home-page/vet-station-home/:id', component: VetStationHomePageComponent, canActivate: [AuthorizationGuard] },
  { path: 'settings', component: SettingsComponent, canActivate: [AuthorizationGuard] },
  { path: 'settings/profile-settings', component: ProfileSettingsComponent, canActivate: [AuthorizationGuard] },
  { path: 'settings/my-pets', component: PetsSettingsComponent, canActivate: [AuthorizationGuard] },
  { path: 'new-appointment/:id', component: AppointmentPageComponent, canActivate: [AuthorizationGuard] },
  { path: 'my-appointments', component: MyAppointmentsComponent, canActivate: [AuthorizationGuard] },

  // Employee+ (permission level >= 2)
  { path: 'settings/vet-station', component: VetStationComponent, canActivate: [roleGuard(2)] },
  { path: 'settings/employees', component: EmployeeListComponent, canActivate: [roleGuard(2)] },
  { path: 'settings/availability', component: AvailabilitySettingsComponent, canActivate: [roleGuard(2)] },

  // Admin only (permission level 4)
  { path: 'admin-panel', component: AdminPanelComponent, canActivate: [roleGuard(4)] },
]

