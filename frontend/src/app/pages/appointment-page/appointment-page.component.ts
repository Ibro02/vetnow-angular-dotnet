import {Component} from '@angular/core';
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";
import {CalendarComponent} from "../../components/common/calendar/calendar.component";
import {AppointmentLayoutComponent} from "../../components/layouts/appointment-layout/appointment-layout.component";
import {TitleComponent} from "../../components/common/title/title.component";
import {ActivatedRoute, Params, Router} from "@angular/router";
import {ProfileService} from "../../services/ProfileService";
import {UserProfile} from "../../services/interfaces/UserProfile";
import axios from "axios";
import {NgForOf} from "@angular/common";
import {FormsModule} from "@angular/forms";
import {TimeSlot} from "./TimeSlot";
import {Config} from "../../config";
import {Animal} from "./Animal";
import {Appointment} from "./Appointment";
import {ToasterService} from "../../services/toaster.service";
@Component({
  selector: 'app-appointment-page',
  standalone: true,
  imports: [
    HeaderTitleComponent,
    CalendarComponent,
    AppointmentLayoutComponent,
    TitleComponent,
    NgForOf,
    FormsModule
  ],
  templateUrl: './appointment-page.component.html',
  styleUrl: './appointment-page.component.css'
})
export class AppointmentPageComponent {
  user: UserProfile | null = null
  pets: Animal[] = []; //todo: make interface Pets
  selectedPet?: any;
  timeSlots?: TimeSlot[]; //todo: make interface TimeSlots
  employeeid?: number;
  employee: any;
  appointmentTime?: string | null;
  newAppointment: any;
  constructor(private route: ActivatedRoute, private router: Router, private profileService: ProfileService, private toaster:ToasterService) {}
async ngOnInit(){
await this.profileService.getUserContent();
this.user = this.profileService.userProfile;
let date = this.route.snapshot.queryParamMap.get('date') ?? new Date().toJSON();

this.route.params.subscribe((params: Params)=> this.employeeid = params['id']);
this.fetchPets();
this.fetchTimeSlots(date);
this.fetchEmployee();
}

async fetchPets(): Promise<void> {
    let url: string = "api/Animal/GetByOwnerId";
    let { data } = await axios.get(Config.address + url + "?id=" + this.user?.id);
    console.log(data);
    this.pets = data;
}

async fetchTimeSlots(date: string = new Date().toJSON()) {
  let url: string = "api/TimeSlot/Get";
  let { data } = await axios.get(Config.address + url + `?employeeid=${this.employeeid}&date=${date.split("T")[0]}`);
  this.timeSlots = data;
}
  async fetchEmployee() {
    let url: string = "api/Employee/Get";
    let { data } = await axios.get(Config.address + url + `?id=${this.employeeid}`);
    this.employee = data;
  }
  changeDate(value: Date) {
    //Query for time slots here
    this.fetchTimeSlots(value.toJSON());
    this.appointmentTime = null;
  }

  prepareAnAppointment(timeslot: TimeSlot) {
    this.appointmentTime = timeslot.slotDateTime.split("T")[0] + " At " + timeslot.appointmentTime;
    this.newAppointment = {
      customerId: this.user?.id,
      vetStationId: this.employee.vetStationId,
      employeeId: this.employeeid,
      timeSlotId: timeslot.id,
      animalId: this.selectedPet?.id
    }
  }

  async makeAnAppointment() {
    const url = "api/Appointment/Add";
    if (this.newAppointment.animalId == null)
      this.toaster.error("Error", "Required Feild: Select Pet!");
    else if (this.newAppointment.timeSlotId == null)
      this.toaster.error("Error", "Required Feild: Time!");
    else if (this.newAppointment.vetStationId == null)
        this.toaster.error("Error", "Whops! Restart page and try again");
    else if (this.newAppointment.employeeId == null)
      this.toaster.error("Error", "Whops! Select a vet/barber you want to schedule for an appointment!");
    else
      await axios.post(Config.address + url, this.newAppointment).then(x=>{
        this.toaster.success("Succes", "You have successfully made an appointment for " + this.appointmentTime + "!");
        this.ngOnInit();
        this.router.navigate(['/']);
      }).catch(err =>{
        this.toaster.error("Error","Ups! An error has occurred!");
        console.log(err.message);
      });
    this.appointmentTime = null;
    this.newAppointment = null;
  }

  afterPetSelect(p: Animal) {
    this.selectedPet = p;
    this.newAppointment.animalId = p.id;

  }
}
