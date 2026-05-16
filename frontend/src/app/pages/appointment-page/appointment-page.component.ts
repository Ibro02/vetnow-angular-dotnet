import {Component, ElementRef, HostListener, ViewChild} from '@angular/core';
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";
import {CalendarComponent} from "../../components/common/calendar/calendar.component";
import {ActivatedRoute, Params, Router} from "@angular/router";
import {ProfileService} from "../../services/ProfileService";
import {UserProfile} from "../../services/interfaces/UserProfile";
import { HttpClient } from "@angular/common/http";
import { firstValueFrom } from "rxjs";
import {NgForOf, NgIf} from "@angular/common";
import {FormsModule} from "@angular/forms";
import {TimeSlot} from "./TimeSlot";
import { environment } from '../../../environment';
import {Animal} from "./Animal";
import {ToasterService} from "../../services/toaster.service";
import { fadeIn, scaleIn } from '../../animations/shared.animations';

@Component({
  selector: 'app-appointment-page',
  standalone: true,
  imports: [
    HeaderTitleComponent,
    CalendarComponent,
    NgForOf,
    NgIf,
    FormsModule
  ],
  templateUrl: './appointment-page.component.html',
  styleUrl: './appointment-page.component.css',
  animations: [fadeIn, scaleIn],
})
export class AppointmentPageComponent {
  user: UserProfile | null = null;
  pets: Animal[] = [];
  selectedPet?: Animal;
  timeSlots?: TimeSlot[];
  employeeid?: number;
  employee: any;
  appointmentTime?: string | null;
  newAppointment: any;

  isLoadingSlots: boolean = false;
  isLoadingPets: boolean = false;

  // Searchable pet dropdown
  isPetDropdownOpen: boolean = false;
  petSearch: string = '';
  @ViewChild('petSearchInput') petSearchInput?: ElementRef<HTMLInputElement>;

  // Close dropdown when user clicks anywhere outside the component
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent) {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      this.isPetDropdownOpen = false;
    }
  }

  get filteredPets(): Animal[] {
    if (!this.petSearch.trim()) return this.pets;
    const q = this.petSearch.toLowerCase().trim();
    return this.pets.filter(p => p.name.toLowerCase().includes(q));
  }

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private profileService: ProfileService,
    private toaster: ToasterService,
    private elementRef: ElementRef,
    private http: HttpClient,
  ) {}

  async ngOnInit() {
    await this.profileService.getUserContent();
    this.user = this.profileService.userProfile;
    const date = this.route.snapshot.queryParamMap.get('date') ?? new Date().toJSON();

    this.route.params.subscribe((params: Params) => this.employeeid = params['id']);

    this.fetchPets();
    this.fetchTimeSlots(date);
    this.fetchEmployee();
  }

  async fetchPets(): Promise<void> {
    this.isLoadingPets = true;
    try {
      const data = await firstValueFrom(
        this.http.get<Animal[]>(`${environment.apiUrl}/api/Animal/GetByOwnerId?id=${this.user?.id}`)
      );
      this.pets = Array.isArray(data) ? data : [];
    } catch {
      this.pets = [];
    } finally {
      this.isLoadingPets = false;
    }
  }

  async fetchTimeSlots(date: string = new Date().toJSON()) {
    this.isLoadingSlots = true;
    this.timeSlots = [];
    try {
      const data = await firstValueFrom(
        this.http.get<TimeSlot[]>(
          `${environment.apiUrl}/api/TimeSlot/Get?employeeid=${this.employeeid}&date=${date.split("T")[0]}`
        )
      );
      // API returns 204 NoContent (empty body) when no slots exist
      this.timeSlots = Array.isArray(data) ? data : [];
    } catch {
      this.timeSlots = [];
    } finally {
      this.isLoadingSlots = false;
    }
  }

  async fetchEmployee() {
    try {
      this.employee = await firstValueFrom(
        this.http.get(`${environment.apiUrl}/api/Employee/Get?id=${this.employeeid}`)
      );
    } catch {
      this.employee = null;
    }
  }

  changeDate(value: Date) {
    this.fetchTimeSlots(value.toJSON());
    this.appointmentTime = null;
    this.newAppointment = null;
  }

  prepareAnAppointment(timeslot: TimeSlot) {
    // Format date nicely: "Monday, March 8"
    const date = new Date(timeslot.slotDateTime);
    const dateStr = date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
    // Format time: "09:00" (trim seconds from TimeSpan string)
    const timeStr = timeslot.appointmentTime.substring(0, 5);

    this.appointmentTime = `${dateStr} at ${timeStr}`;
    this.newAppointment = {
      customerId: this.user?.id,
      vetStationId: this.employee?.vetStationId,
      employeeId: this.employeeid,
      timeSlotId: timeslot.id,
      animalId: this.selectedPet?.id ?? null
    };
  }

  async makeAnAppointment() {
    if (!this.newAppointment) return;

    if (this.newAppointment.animalId == null)
      return this.toaster.error("Missing field", "Please select a pet before booking.");
    if (this.newAppointment.timeSlotId == null)
      return this.toaster.error("Missing field", "Please select a time slot.");
    if (this.newAppointment.vetStationId == null)
      return this.toaster.error("Error", "Something went wrong. Please refresh and try again.");
    if (this.newAppointment.employeeId == null)
      return this.toaster.error("Error", "Could not identify the specialist. Please go back and try again.");

    try {
      await firstValueFrom(
        this.http.post(`${environment.apiUrl}/api/Appointment/Add`, this.newAppointment)
      );
      this.toaster.success('Appointment booked!', `See you on ${this.appointmentTime}!`);
      this.router.navigate(['/home-page']);
    } catch (err: any) {
      this.toaster.error('Booking failed', 'Something went wrong. Please try again.');
    } finally {
      this.appointmentTime = null;
      this.newAppointment = null;
    }
  }

  togglePetDropdown() {
    this.isPetDropdownOpen = !this.isPetDropdownOpen;
    if (this.isPetDropdownOpen) {
      // Wait one tick for *ngIf to render the input, then focus it
      setTimeout(() => this.petSearchInput?.nativeElement?.focus(), 50);
    } else {
      this.petSearch = '';
    }
  }

  selectPet(p: Animal) {
    this.afterPetSelect(p);
    this.isPetDropdownOpen = false;
    this.petSearch = '';
  }

  afterPetSelect(p: Animal) {
    this.selectedPet = p;
    if (this.newAppointment) {
      this.newAppointment.animalId = p.id;
    }
  }
}
