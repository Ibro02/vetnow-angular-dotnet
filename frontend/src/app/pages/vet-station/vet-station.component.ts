import { Component, OnInit, forwardRef } from '@angular/core';
import { BoxContainerComponent } from '../../components/common/box-container/box-container.component';
import { SignInInputComponent } from '../../components/common/sign-in-input/sign-in-input.component';
import { PageTitleContainerComponent } from '../../components/common/page-title-container/page-title-container.component';
import { InputComponent } from '../../components/common/input/input.component';
import { InputButtonComponent } from '../../components/common/input-button/input-button.component';
import { NgFor, NgIf } from '@angular/common';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
import axios, { AxiosResponse } from 'axios';
import {
  FormControl,
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  NG_VALUE_ACCESSOR,
  Validator,
} from '@angular/forms';
import { ButtonComponent } from '../../components/common/button/button.component';
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";

@Component({
  selector: 'app-vet-station',
  standalone: true,
  templateUrl: './vet-station.component.html',
  styleUrl: './vet-station.component.css',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      multi: true,
      useExisting: forwardRef(() => VetStationComponent),
    },
  ],
  imports: [
    NgFor,
    NgIf,
    ReactiveFormsModule,
    GoogleMapsModule,
    GoogleMap,
    BoxContainerComponent,
    SignInInputComponent,
    PageTitleContainerComponent,
    InputComponent,
    InputButtonComponent,
    ButtonComponent,
    HeaderTitleComponent,
  ],
})
export class VetStationComponent implements OnInit {
  id: number = 1; //temporary

  public mapOptions: google.maps.MapOptions = {
    center: {
      lat: 43.343777,
      lng: 17.807758,
    },
    mapTypeId: 'hybrid',
    zoomControl: true,
    scrollwheel: true,
    disableDoubleClickZoom: true,
    maxZoom: 15,
    minZoom: 8,
  };

  //public vetStation: IVetStation
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
    name: new FormControl(''),
    city: new FormControl(''),
    country: new FormControl(''),
    contactNumber: new FormControl(''),
    email: new FormControl(''),
    address: new FormControl(''),
    description: new FormControl(''),
    onField: new FormControl(false),
    inOffice: new FormControl(false),
    parking: new FormControl(false),
    wheelchair: new FormControl(false),
    wifi: new FormControl(false),
    stationImage: new FormControl('')
  });
  /**
   *
   */
  constructor(private fb: FormBuilder) {
    this.fetchVetStationInfo(fb);
  }
  ngOnInit(): void {
    this.fetchCountries();
    //this.fetchCities();
    // navigator.geolocation.getCurrentPosition((position) => {
    //     this.mapOptions.center = {
    //       lat: position?.coords.latitude ?? 46.788,
    //       lng: position?.coords.longitude ?? -71.3893,
    //     }
    //     console.log("what");
    //   });
  }

  async saveChanges() {
    const apiUrl = `https://localhost:44308/api/VetStation/Edit/${this.id.toString()}`;
    await axios
      .put(apiUrl, this.vetStationFormGroup.value)
      .then((response: AxiosResponse<any>) => {
        window.alert("Success!");
      })
      .catch((err) => {
        window.alert(err);
      });
  }

  fetchVetStationInfo = async (fb: FormBuilder) => {
    const apiUrl: string = `https://localhost:44308/api/VetStation/Get?id=${this.id.toString()}`;

    await axios
      .get(apiUrl)
      .then((response: AxiosResponse<IVetStation[]>) => {


        this.vetStationFormGroup = this.fb.group<IVetStation>({
          name: response.data[0].name,
          country: response.data[0].country,
          city: response.data[0].city,
          contactNumber: response.data[0].contactNumber,
          email: response.data[0].email,
          stationImage: '',
          address: response.data[0].address,
          description: response.data[0].description,
          onField: response.data[0].onField,
          inOffice: response.data[0].inOffice,
          parking: response.data[0].parking,
          wheelchair: response.data[0].wheelchair,
          wifi: response.data[0].wifi,
        });
    this.fetchCities();

      })
      .catch((error: Error) => {
        console.error('Error fetching cities:', error);
      });
  };

  fetchCountries = async () => {
    const apiUrl: string = `https://restcountries.com/v3.1/all`;

    await axios
      .get(apiUrl)
      .then((response: AxiosResponse<any[]>) => {
        let counter = 0;
        response.data.forEach((_country) => {
          this.countries[counter] = { id: counter, name: _country.name.common };
          counter++;
        });
        this.countries.sort((a, b) => a.name.localeCompare(b.name));
      })
      .catch((error: Error) => {
        console.error('Error fetching cities:', error);
      });
  };

  fetchCities = async () => {
    const apiUrl: string =
      'https://countriesnow.space/api/v0.1/countries/cities';

   await axios
      .post(apiUrl, {
        country:
          this.vetStationFormGroup.value.country?.toLowerCase() ??
          'bosnia and herzegovina',
      })
      .then((response: AxiosResponse<{ data: City[] }>) => {
        const _cities: City[] = response.data.data;
        let counter = 0;
        _cities.forEach((city) => {
          this.cities[counter] = { id: counter, name: city.toString() };
          counter++;
        });
        this.cities.sort((a, b) => a.name.localeCompare(b.name));
      })
      .catch((error: Error) => {
        console.error('Error fetching cities:', error);
      });
  };

  countryChange() {
    this.fetchCities();
    this.vetStationFormGroup.value.city = null;
  }

  test() {
    console.log(this.vetStationFormGroup.value);
  }

  handleChange(id: number) {
    this.accessibilityAndMobilityButtons[id].value =
      !this.accessibilityAndMobilityButtons[id].value;
    //console.log(this.dropdown[i].children[j])
  }
  getInputValue = (value: string) => {
    this.inputValue = value;
    // console.log(this.name.value); //@todo - fetch data from inputs with FromControls
    //console.log(this.vetStationFormGroup?.value); //do like this
  };

  receiveImageURL(event: string) {
    this.vetStationFormGroup.value.stationImage = event;
  }
}
export interface DropbdownArr {
  id?: number;
  name: string;
}
interface City {
  city: string;
}

export interface IVetStation {
  name: string;
  city: string; //change???
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
export interface IFacility {
  id: number;
  name: string;
  key: 'onField' | 'inOffice' | 'parking' | 'wheelchair' | 'wifi';
  value: boolean;
}
export class FileValidator implements Validator {
  static validate(c: FormControl): { [key: string]: any } {
    return c.value == null || c.value.length == 0
      ? { required: true }
      : { required: false };
  }

  validate(c: FormControl): { [key: string]: any } {
    return FileValidator.validate(c);
  }
}
