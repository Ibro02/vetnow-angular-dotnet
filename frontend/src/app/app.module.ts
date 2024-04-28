import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { routes } from './app.routes';
import { BrowserModule } from '@angular/platform-browser';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';

@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    BrowserModule,
    GoogleMap,
    GoogleMapsModule,
    RouterModule.forRoot(routes),
  ],
  exports: [RouterModule],
  bootstrap: [AppModule],
})
export class AppModule {}
