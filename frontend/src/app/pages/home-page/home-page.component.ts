import {Component, DoCheck, Injectable, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import {MyAuthService} from "../../services/MyAuth";
import {ProfileService} from "../../services/ProfileService";
import {NgForOf, NgIf} from "@angular/common";
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faStar} from "@fortawesome/free-solid-svg-icons";
import {VetCardComponent} from "../../components/group/vet-card/vet-card.component";
import {InputComponent} from "../../components/common/search-input/search-input.component";
import {VetStationList,VetStation} from "./VetStation";
import axios from "axios";
import {HttpClient} from "@angular/common/http";
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { Subject, Observable } from 'rxjs';
import {VetStationService} from "../../services/VetStationSearch";
import { Config } from '../../config';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-home-page',
  standalone: true,
  imports: [
    NgForOf,
    FaIconComponent,
    VetCardComponent,
    InputComponent,
    NgIf,
    RouterLink,
  ],
  templateUrl: './home-page.component.html',
  styleUrl: './home-page.component.css'
})
export class HomePageComponent implements OnInit{

  private  searchTextChanged = new Subject<string>();
  private searchObservable: Observable<string> = this.searchTextChanged.asObservable();
  private inputValue = ""
isLoading = false;
  vetStations?: VetStationList = {vetStations:[]};
   ngOnInit() {
 this.getAll();
     this.searchObservable
       .pipe(
         debounceTime(800), // Debounce for 1.5 seconds
         distinctUntilChanged(), // Only emit when the value changes
         switchMap(value => this.vetStationService.setValues(value)) // Call your function
       )
       .subscribe();
  this.profileService.getUserContent();
  }

  constructor(public myAuthService:MyAuthService,public profileService:ProfileService,public httpClient:HttpClient,public vetStationService:VetStationService) {

}

  protected readonly faStar = faStar;



 async handleChange(children:any) {
if (children.target.value === "")
  this.getAll();
else
{
this.vetStationService.isLoading = true;
this.searchTextChanged.next(children.target.value);
}
 }

  getAll()
  {

    let url = Config.address + "api/VetStation/GetAll";
    this.httpClient.get<VetStation[]>(url).subscribe(async x => {
      let vetStationsArr: VetStation[] =  x
      this.vetStationService.vetStations = {vetStations:[...vetStationsArr]}
    });

  }

}

