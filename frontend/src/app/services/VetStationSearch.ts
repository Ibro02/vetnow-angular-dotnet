// google-login.service.ts
import { Injectable } from '@angular/core';
import {UserProfile} from "./interfaces/UserProfile";
import axios from "axios";
import {MyAuthService} from "./MyAuth";
import {VetStationList} from "../pages/home-page/VetStation";
import { Config } from '../config';


@Injectable({
  providedIn: 'root',
})
export class VetStationService {
  dropdown =
    [
      {
        "key": 0,
        "title":"Location",
        "children":[
          {
            'key': 0,
            'route':'location',
            'name': 'Closest Station',
            'value': false,
          }
        ]
      },
      {
        "key": 1,
        "title":"Service type",
        "children":[
          {
            'key': 0,
            'route':'isInOffice',
            'name': 'In Office',
            'value': false,
          },
          {
            'key': 1,
            'route':'isOnField',
            'name':'On Field',
            'value': false,
          }

        ]
      },
      {
        "key": 2,
        "title":"Accommodation",
        "children":[
          {
            'key': 0,
            'route':'parking',
            'name': 'Parking',
            'value': false,
          },
          {
            'key': 1,
            'route':'wheelchair',
            'name':'Wheelchair',
            'value': false,
          },
          {
            'key': 2,
            'route':'wifi',
            'name':'Wi-fi',
            'value': false,
          }

        ]
      }
    ]

  constructor(private myAuthService:MyAuthService) {
  }
  public vetStations?: VetStationList = {vetStations:[]};
  public isLoading:boolean = false;
  async setValues(value?:string)
  {
    let arr = this.dropdown;
    let requestLink = Config.address + "api/VetStationSearch";
    let url = requestLink + (value?"?name="+ value:"?");

    var counter = 0;
    arr.map(x=>
    {
      x.children.map(y=>
      {
        if (!(url.length == requestLink.length + 1) && y.value && !value) {
          url += "&";
        }

        url += (y.value?  y.route+"="+y.value:"")

        counter++;
      })
    })

    let {data} = await axios.get<VetStationList>(url);
    this.isLoading = false;
    this.vetStations = data;
  }



}
