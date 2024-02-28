import {Component, Input, OnChanges} from '@angular/core';
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import { faWifi } from '@fortawesome/free-solid-svg-icons';
import { faWheelchair } from '@fortawesome/free-solid-svg-icons';
import { faP } from '@fortawesome/free-solid-svg-icons';
import {VetStation, VetStationList} from "../../../pages/home-page/VetStation";
import {NgIf} from "@angular/common";
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-vet-card',
  standalone: true,
  imports: [FaIconComponent, NgIf,RouterLink],
  templateUrl: './vet-card.component.html',
  styleUrl: './vet-card.component.css'
})
export class VetCardComponent implements OnChanges{

  ngOnChanges() {

  }

  @Input() vetStation?:VetStation;

  public readonly faWifi = faWifi;
  public readonly faWheelchair = faWheelchair;
  public readonly faP = faP;



}
