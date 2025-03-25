import { Component, OnInit } from '@angular/core';
import { ImageCarouselComponent } from '../common/image-carousel/image-carousel.component';
import { ServiceSwipperComponent } from '../common/service-swiper/service-swiper.component';
import { AboutUsFooterComponent } from './about-us-footer/about-us-footer.component';
import {ActivatedRoute, RouterLink} from '@angular/router';
import axios from 'axios';
import { Config } from '../../config';
import {Employee} from "./Employee";
import {NgForOf, NgIf} from "@angular/common";
@Component({
  selector: 'app-vet-station-home-page',
  standalone: true,
  imports: [ImageCarouselComponent, ServiceSwipperComponent, AboutUsFooterComponent, NgIf, NgForOf, RouterLink],
  templateUrl: './vet-station-home-page.component.html',
  styleUrl: './vet-station-home-page.component.css'
})
export class VetStationHomePageComponent implements OnInit{

  public vetStationId:number = 0;
  public vetStationInfo:any;
  apiRoute = "api/VetStation/Get/";
  vetStation: any;
  employeeList?: Employee[];
  date = new Date().toJSON();
  constructor(router: ActivatedRoute)
  {
   router.params.subscribe(params =>  this.vetStationId = <number>params["id"]);

  }

  async fetchVetStats()
{
  let url = Config.address + this.apiRoute;
  let {data} = await axios.get(url, {
    params: {
      id: this.vetStationId
    }
  });

  this.vetStation = data[0];

  this.vetStationInfo =
  {
   // email: this.vetStation.email, @todo - there is no email in database!!! >:(
  //  location/address: this.vetStation.location @todo - there is no location/address in database!!! >:((
  contactNumber: this.vetStation.contactNumber
  }
}

ngOnInit(): void {
  this.fetchVetStats();
  console.log(this.vetStation)
}

  async openEmployeeTablePopUp(serviceid: number) {
    //1 - CheckUp
    //2 - Surgery
    //3 - Barber
    let apiRoute = "api/Employee/GetByVetStationId";
    let url = Config.address + apiRoute;
    let {data} = await axios.get(url, {
      params: {
        //id: serviceid
        id: this.vetStationId
      }
    });
    this.employeeList = data;

  }

  protected readonly Object = Object;

  makeAnAppointment(id: number) {

  }
}
