import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { routes } from './app.routes';
import { BrowserModule } from '@angular/platform-browser';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { ToastrModule } from 'ngx-toastr';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { AddEmployeeComponent } from './components/group/add-employee/add-employee.component';
@NgModule({
  declarations: [AddEmployeeComponent],
  imports: [
    CommonModule,
    BrowserModule,
    GoogleMap,
    GoogleMapsModule,
    FormsModule,
    RouterModule.forRoot(routes),
    ToastrModule.forRoot(),
    BrowserAnimationsModule,
    ReactiveFormsModule
  ],
  exports: [RouterModule],
  bootstrap: [AppModule],
})
export class AppModule {}
