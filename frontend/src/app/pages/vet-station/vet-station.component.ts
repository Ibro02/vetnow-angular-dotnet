import { Component, OnInit } from '@angular/core';
import { BoxContainerComponent } from '../../components/common/box-container/box-container.component';
import { SignInInputComponent } from '../../components/common/sign-in-input/sign-in-input.component';
import { PageTitleContainerComponent } from "../../components/common/page-title-container/page-title-container.component";
import { InputComponent } from '../../components/common/input/input.component';
import { InputButtonComponent } from "../../components/common/input-button/input-button.component";
import { NgFor, NgIf } from '@angular/common';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';

@Component({
    selector: 'app-vet-station',
    standalone: true,
    templateUrl: './vet-station.component.html',
    styleUrl: './vet-station.component.css',
    imports: [NgFor,NgIf,GoogleMapsModule, GoogleMap, BoxContainerComponent, SignInInputComponent, PageTitleContainerComponent, InputComponent, InputButtonComponent]
})
export class VetStationComponent implements OnInit{

ngOnInit(): void {
    
}

public accessibilityAndMobilityButtons = 
[
{id: 0, name:"Wifi", value: false,},
{id: 1, name:"Parking", value: false,},
{id: 2, name:"Wheelchair", value: false,},
{id: 3, name:"In Office", value: false,},
{id: 4, name:"On Field", value: false,},
]
    handleChange(id:number) {
    this.accessibilityAndMobilityButtons[id].value =  !this.accessibilityAndMobilityButtons[id].value;
    //console.log(this.dropdown[i].children[j])
      }
}
