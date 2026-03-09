import {Component, Input, OnChanges, OnInit, AfterViewInit, SimpleChanges} from '@angular/core';
import {NgIf, NgFor, DatePipe} from "@angular/common";
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faHome, faEnvelope, faShop, faUser, faGear} from "@fortawesome/free-solid-svg-icons";
import {MyAuthService} from "../services/MyAuth";
import {ProfileService} from "../services/ProfileService";
import {AppointmentService, AppointmentDto} from "../services/AppointmentService";
import { Router, RouterModule, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [
    NgIf,
    NgFor,
    DatePipe,
    FaIconComponent,
    RouterModule
  ],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.css'
})
export class NavbarComponent implements OnChanges, OnInit, AfterViewInit {

  @Input() public isLogged: boolean = false;
  upcomingAppointments: AppointmentDto[] = [];
  isStaff: boolean = false;
  isLoadingSchedule: boolean = false;

  constructor(
    public myAuthService: MyAuthService,
    private profileService: ProfileService,
    private appointmentService: AppointmentService,
    private router: Router,
  ) {}

  async ngOnInit() {
    await this.loadSchedule();

    // Refresh schedule on every navigation (e.g. after booking a new appointment)
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd)
    ).subscribe(() => this.loadSchedule());

    // Refresh when appointments are cancelled or rescheduled
    this.appointmentService.changed$.subscribe(() => this.loadSchedule());
  }

  ngAfterViewInit() {
    // Refresh schedule every time the sidebar is opened
    const offcanvas = document.getElementById('offcanvasWithBackdrop');
    if (offcanvas) {
      offcanvas.addEventListener('show.bs.offcanvas', () => this.loadSchedule());
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    this.isLogged = this.myAuthService.IsLogged();

    // Reload schedule when user logs in (isLogged flips to true)
    if (changes['isLogged'] && this.isLogged) {
      this.loadSchedule();
    }
  }

  async loadSchedule() {
    if (!this.myAuthService.IsLogged()) return;
    this.isLoadingSchedule = true;
    try {
      await this.profileService.getUserContent();
      const user = this.profileService.userProfile;
      if (!user) return;

      this.isStaff = user.isVet || user.isNurse || user.isBarber || user.isMainVet;

      if (this.isStaff) {
        this.upcomingAppointments = (await this.appointmentService.getByEmployeeId(user.id)).slice(0, 3);
      } else {
        this.upcomingAppointments = (await this.appointmentService.getByCustomerId(user.id)).slice(0, 3);
      }
    } catch {
      this.upcomingAppointments = [];
    } finally {
      this.isLoadingSchedule = false;
    }
  }

  protected readonly faHome = faHome;
  protected readonly faUser = faUser;
  protected readonly faShop = faShop;
  protected readonly faEnvelope = faEnvelope;
  protected readonly faGear = faGear;
}
