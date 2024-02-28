import { Component } from '@angular/core';
import { BoxContainerComponent } from '../../components/common/box-container/box-container.component';
import { SignInInputComponent } from '../../components/common/sign-in-input/sign-in-input.component';
@Component({
  selector: 'app-vet-station',
  standalone: true,
  imports: [BoxContainerComponent, SignInInputComponent],
  templateUrl: './vet-station.component.html',
  styleUrl: './vet-station.component.css'
})
export class VetStationComponent {

}
