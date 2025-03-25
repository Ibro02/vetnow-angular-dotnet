import {Component, EventEmitter, Output} from '@angular/core';

@Component({
  selector: 'app-service-swipper',
  standalone: true,
  imports: [],
  templateUrl: './service-swiper.component.html',
  styleUrl: './service-swiper.component.css'
})
export class ServiceSwipperComponent {
 @Output() onClick = new EventEmitter<any>();
 checkUp: number = 1;
 surgery: number = 2;
 barber: number = 3;
 makeAnAppointment(serviceid: number) {
  this.onClick.emit(serviceid);
 }
}
