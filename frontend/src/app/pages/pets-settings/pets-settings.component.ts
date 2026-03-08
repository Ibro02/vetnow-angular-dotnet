import { Component } from '@angular/core';
import {PetCardComponent} from "../../components/group/pet-card/pet-card.component";

@Component({
  selector: 'app-pets-settings',
  standalone: true,
  imports: [
    PetCardComponent
  ],
  templateUrl: './pets-settings.component.html',
  styleUrl: './pets-settings.component.css'
})
export class PetsSettingsComponent {

}
