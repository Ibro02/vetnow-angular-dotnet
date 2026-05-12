import { Component, OnInit, ElementRef, HostListener, ViewChild } from '@angular/core';
import { CalendarComponent } from '../common/calendar/calendar.component'; // Import your existing calendar
import { ActivatedRoute, Router } from '@angular/router';
import { NgForOf, NgIf, NgClass, DatePipe } from "@angular/common";
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { Config } from '../../config';
import { Employee } from "./Employee";
import { Animal } from "../../pages/appointment-page/Animal";
import { TimeSlot } from "../../pages/appointment-page/TimeSlot";
import { ToasterService } from "../../services/toaster.service";
import { ProfileService } from "../../services/ProfileService";
import { RouterLink } from "@angular/router";
import { fadeIn, scaleIn } from '../../animations/shared.animations';
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faClipboardCheck, faCut, faStethoscope, faSyringe, faUserMd, faTimes, faSearchPlus} from "@fortawesome/free-solid-svg-icons";
@Component({
  selector: 'app-vet-station-home-page',
  standalone: true,
  imports: [CalendarComponent, NgIf, NgForOf, NgClass, DatePipe, FormsModule, RouterLink, FaIconComponent],
  templateUrl: './vet-station-home-page.component.html',
  styleUrl: './vet-station-home-page.component.css',
  animations: [fadeIn, scaleIn]
})
export class VetStationHomePageComponent implements OnInit {
  public vetStationId: number = 0;
  vetStation: any;
  employeeList?: Employee[];
  vetStationFullAddress: string = 'Not provided';
  // Booking State
  selectedServiceId?: number;
  selectedEmployee?: Employee;
  selectedPet?: Animal;
  pets: Animal[] = [];
  timeSlots: TimeSlot[] = [];

  faTimes = faTimes;
  faSearchPlus = faSearchPlus;
  showGallery = false;
  selectedImage: string | null = null;
  isZoomed = false;

  appointmentTime?: string | null;
  newAppointment: any;
  isLoadingSlots = false;
  isPetDropdownOpen = false;
  petSearch = '';

  @ViewChild('petSearchInput') petSearchInput?: ElementRef<HTMLInputElement>;

  private vetApi = "api/Employee/GetVetsByVetStationId"
  private barberApi = "api/Employee/GetBarbersByVetStationId"
  private nurseApi = "api/Employee/GetNursesByVetStationId"

  vetServices = [
    { id: 1, name: 'Checkup', icon: faStethoscope, serviceId: 1, api: this.vetApi },
    { id: 2, name: 'Surgery', icon: faClipboardCheck, serviceId: 1, api: this.vetApi},
    { id: 3, name: 'Grooming', icon: faCut, serviceId: 2, api: this.barberApi},
    { id: 4, name: 'Vaccine', icon: faSyringe, serviceId: 3, api: this.nurseApi }
  ];

  galleryImages = [
    'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1628009368231-7bb7cfcb0def?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1597233545218-358006460790?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&q=80&w=800'
  ];
  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private profileService: ProfileService,
    private toaster: ToasterService,
    private elementRef: ElementRef,
    private http: HttpClient,
  ) {
    this.route.params.subscribe(params => this.vetStationId = +params["id"]);
  }

  async ngOnInit() {
    await this.profileService.getUserContent();
    this.fetchVetStats();
    this.fetchPets();
  }

  async fetchVetStats() {
    try {
      const data: any[] = await firstValueFrom(
        this.http.get<any[]>(Config.address + 'api/VetStation/Get/', { params: { id: this.vetStationId } })
      );
      this.vetStation = data[0];
      this.vetStationFullAddress = `${this.vetStation.address}, ${this.vetStation.city},\n${this.vetStation.country}`;
    } catch { /* failed to load vet station */ }
  }

  async fetchPets() {
    try {
      const data = await firstValueFrom(
        this.http.get<Animal[]>(Config.address + `api/Animal/GetByOwnerId?id=${this.profileService.userProfile?.id}`)
      );
      this.pets = Array.isArray(data) ? data : [];
    } catch { this.pets = []; }
  }

  async fetchTimeSlots(date: string) {
    if (!this.selectedEmployee) return;
    this.isLoadingSlots = true;
    try {
      const data = await firstValueFrom(
        this.http.get<TimeSlot[]>(Config.address + `api/TimeSlot/Get?employeeid=${this.selectedEmployee.id}&date=${date.split("T")[0]}`)
      );
      this.timeSlots = Array.isArray(data) ? data : [];
    } catch { this.timeSlots = []; }
    finally { this.isLoadingSlots = false; }
  }

  async selectService(service: any) {
    this.selectedServiceId = service.id;
    this.selectedEmployee = undefined;
    const data: any = await firstValueFrom(
      this.http.get(Config.address + service.api, { params: { id: this.vetStationId } })
    );
    this.employeeList = data.dataItems;
  }
  toggleGallery(state: boolean) {
    this.showGallery = state;
    // Prevent body scroll when gallery is open
    document.body.style.overflow = state ? 'hidden' : 'auto';
  }
  openZoom(img: string) {
    this.selectedImage = img;
    this.isZoomed = false;
  }

  closeZoom() {
    this.selectedImage = null;
    this.isZoomed = false;
  }
  isLoaded = () => this.vetStation != null;
  selectEmployee(e: Employee) {
    this.selectedEmployee = e;
    this.fetchTimeSlots(new Date().toJSON());
  }

  changeDate(date: Date) {
    this.fetchTimeSlots(date.toJSON());
    this.appointmentTime = null;
  }

  prepareBooking(slot: TimeSlot) {
    const d = new Date(slot.slotDateTime);
    const dateStr = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    const timeStr = slot.appointmentTime.substring(0, 5);

    this.appointmentTime = `${dateStr} at ${timeStr}`;
    this.newAppointment = {
      customerId: this.profileService.userProfile?.id,
      vetStationId: this.vetStationId,
      employeeId: this.selectedEmployee?.id,
      timeSlotId: slot.id,
      animalId: this.selectedPet?.id
    };
  }

  async confirmBooking() {
    if (!this.selectedPet) return this.toaster.error("Selection Required", "Please select a pet.");
    try {
      await firstValueFrom(
        this.http.post(Config.address + 'api/Appointment/Add', this.newAppointment)
      );
      this.toaster.success("Booked!", "See you soon.");
      this.router.navigate(['/home-page']);
    } catch { this.toaster.error("Error", "Booking failed."); }
  }

  selectPet(p: Animal) {
    this.selectedPet = p;
    if (this.newAppointment) this.newAppointment.animalId = p.id;
    this.isPetDropdownOpen = false;
  }

  protected readonly faUserMd = faUserMd;

  displayRoleName(id: number) {
    if (id === 1) {
      return 'Veterinarian';
    } else if (id === 2) {
      return 'Barber';
    } else if (id === 3) {
      return 'Nurse';
    } else {
      return 'Veterinarian';
    }
  }
}
