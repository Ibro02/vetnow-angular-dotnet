import { Component, OnInit, AfterViewInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { BoxContainerComponent } from '../../components/common/box-container/box-container.component';
import { SignInInputComponent } from '../../components/common/sign-in-input/sign-in-input.component';
import { PageTitleContainerComponent } from '../../components/common/page-title-container/page-title-container.component';
import { InputComponent } from '../../components/common/input/input.component';
import { InputButtonComponent } from '../../components/common/input-button/input-button.component';
import { ButtonComponent } from '../../components/common/button/button.component';
import { HeaderTitleComponent } from "../../components/common/header-title/header-title.component";

import { NgFor, NgIf } from '@angular/common';
import { FormControl, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';

import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import * as L from 'leaflet';
import {ToasterService} from "../../services/toaster.service";
import {MyAuthService} from "../../services/MyAuth";
import { environment } from '../../../environment';

@Component({
  selector: 'app-vet-station',
  standalone: true,
  templateUrl: './vet-station.component.html',
  styleUrl: './vet-station.component.css',
  imports: [
    NgFor,
    NgIf,
    ReactiveFormsModule,
    BoxContainerComponent,
    SignInInputComponent,
    PageTitleContainerComponent,
    InputComponent,
    InputButtonComponent,
    ButtonComponent,
    HeaderTitleComponent,
  ],
})
export class VetStationComponent implements OnInit, AfterViewInit, OnDestroy {

  id: number = 1;

  showCropWizard = false;

  @ViewChild('mapContainer', { static: false }) mapContainer!: ElementRef;

  map!: L.Map;
  marker!: L.Marker;

  public countries: DropbdownArr[] = [];
  public cities: DropbdownArr[] = [];

  inputValue?: string;

  public accessibilityAndMobilityButtons = [
    { id: 0, name: 'Wifi', key: 'wifi', value: false },
    { id: 1, name: 'Parking', key: 'parking', value: false },
    { id: 2, name: 'Wheelchair', key: 'wheelchair', value: false },
    { id: 3, name: 'In Office', key: 'inOffice', value: false },
    { id: 4, name: 'On Field', key: 'onField', value: false },
  ];

  vetStationFormGroup = new FormGroup({
    name:          new FormControl('', [Validators.required, Validators.minLength(2), Validators.maxLength(100)]),
    city:          new FormControl('', [Validators.maxLength(100)]),
    country:       new FormControl('', [Validators.maxLength(100)]),
    contactNumber: new FormControl('', [Validators.required, Validators.pattern(/^\+?[\d\s\-()\.\+]{7,15}$/)]),
    email:         new FormControl('', [Validators.required, Validators.email, Validators.maxLength(254)]),
    address:       new FormControl('', [Validators.required, Validators.maxLength(200)]),
    description:   new FormControl('', [Validators.maxLength(1000)]),
    onField:       new FormControl(false),
    inOffice:      new FormControl(false),
    parking:       new FormControl(false),
    wheelchair:    new FormControl(false),
    wifi:          new FormControl(false),
    stationImage:  new FormControl(''),
  });

  constructor(private fb: FormBuilder, public toaster: ToasterService, private myAuthService: MyAuthService, private http: HttpClient) {
    this.fetchVetStationInfo();
  }

  ngOnInit(): void {}

  ngAfterViewInit(): void {
    this.initMap();
  }

  ngOnDestroy(): void {
    if (this.map) {
      this.map.remove(); // prevents "map already initialized" error
    }
  }

  initMap(): void {

    const defaultLat = 43.8563;
    const defaultLng = 18.4131;

    const iconDefault = L.icon({
      iconRetinaUrl: 'assets/marker-icon-2x.png',
      iconUrl: 'assets/marker-icon.png',
      shadowUrl: 'assets/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      tooltipAnchor: [16, -28],
      shadowSize: [41, 41]
    });

    L.Marker.prototype.options.icon = iconDefault;

    this.map = L.map(this.mapContainer.nativeElement, {
      center: [defaultLat, defaultLng],
      zoom: 12,
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(this.map);

    this.marker = L.marker([defaultLat, defaultLng], { draggable: true }).addTo(this.map);

    // Click on map -> move marker & reverse geocode
    this.map.on('click', (event: L.LeafletMouseEvent) => {
      const { lat, lng } = event.latlng;
      this.marker.setLatLng([lat, lng]);
      this.reverseGeocode(lat, lng);
    });

    // Drag marker -> reverse geocode
    this.marker.on('dragend', () => {
      const position = this.marker.getLatLng();
      this.reverseGeocode(position.lat, position.lng);
    });
  }

  reverseGeocode(lat: number, lng: number): void {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`;

    fetch(url, {
      headers: { 'Accept-Language': 'en' }
    })
      .then(response => response.json())
      .then(data => {
        if (data && data.address) {
          const city = data.address.city || data.address.town || data.address.village || data.address.municipality || '';
          const country = data.address.country || '';

          this.vetStationFormGroup.controls.city.setValue(city);
          this.vetStationFormGroup.controls.country.setValue(country);
        }
      })
      .catch(err => {
        // reverse geocoding failed
      });
  }

  async saveChanges() {
    if (this.vetStationFormGroup.invalid) {
      this.toaster.error('Validation Error', 'Please correct the form errors before saving.');
      return;
    }

    const apiUrl = `${environment.apiUrl}/api/VetStation/Edit/${this.id}`;

    try {
      await firstValueFrom(
        this.http.put(apiUrl, this.vetStationFormGroup.value)
      );
      this.toaster.success("Changes saved successfully!");
    } catch (err: any) {
      this.toaster.error("Whops!", err.message);
    }
  }

  fetchVetStationInfo = async () => {
    const apiUrl = `${environment.apiUrl}/api/VetStation/Get?id=${this.id}`;

    try {
      const response = await firstValueFrom(
        this.http.get<IVetStation[]>(apiUrl)
      );
      const data = response[0];

      this.vetStationFormGroup.patchValue({
        name: data.name,
        country: data.country,
        city: data.city,
        contactNumber: data.contactNumber,
        email: data.email,
        address: data.address,
        description: data.description,
        onField: data.onField,
        inOffice: data.inOffice,
        parking: data.parking,
        wheelchair: data.wheelchair,
        wifi: data.wifi,
      });
    } catch {
      // failed to fetch vet station
    }
  };

  handleChange(id: number) {
    this.accessibilityAndMobilityButtons[id].value =
      !this.accessibilityAndMobilityButtons[id].value;
  }

  getInputValue = (value: string) => {
    this.inputValue = value;
  };

  receiveImageURL(event: string) {
    this.vetStationFormGroup.value.stationImage = event;
  }
}

export interface DropbdownArr {
  id?: number;
  name: string;
}

export interface IVetStation {
  name: string;
  city: string;
  country: string;
  contactNumber: string;
  email: string;
  stationImage: string;
  address: string;
  description: string;
  onField: boolean;
  inOffice: boolean;
  parking: boolean;
  wheelchair: boolean;
  wifi: boolean;
}
