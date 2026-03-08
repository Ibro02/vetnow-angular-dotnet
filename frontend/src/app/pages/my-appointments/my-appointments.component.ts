import { Component, OnInit } from '@angular/core';
import { NgIf, NgFor, NgClass, NgStyle, DatePipe } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ProfileService } from '../../services/ProfileService';
import { AppointmentService, AppointmentDto } from '../../services/AppointmentService';
import { UserProfile } from '../../services/interfaces/UserProfile';
import { ToasterService } from '../../services/toaster.service';
import { TableComponent, TableColumn, TableAction } from '../../components/common/table/table.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { CalendarComponent } from '../../components/common/calendar/calendar.component';
import axios from 'axios';
import { Config } from '../../config';

@Component({
  selector: 'app-my-appointments',
  standalone: true,
  imports: [
    NgIf, NgFor, NgClass, NgStyle, DatePipe, FormsModule,
    RouterModule, TableComponent, HeaderTitleComponent, CalendarComponent
  ],
  templateUrl: './my-appointments.component.html',
  styleUrl: './my-appointments.component.css'
})
export class MyAppointmentsComponent implements OnInit {
  user: UserProfile | null = null;
  isStaff: boolean = false;
  appointments: AppointmentDto[] = [];
  selectedAppointment: AppointmentDto | null = null;
  isLoading: boolean = false;

  // Date navigator for regular user view
  selectedDate: Date = new Date();

  // Staff table config
  staffColumns: TableColumn[] = [
    { key: 'slotDateTime', label: 'Date', type: 'date' },
    { key: 'appointmentTime', label: 'Time', type: 'text' },
    { key: 'customerFirstName', key2: 'customerLastName', label: 'Customer', type: 'avatar' },
    { key: 'animalName', label: 'Pet', type: 'text' },
    { key: 'speciesName', label: 'Species', type: 'badge' }
  ];

  staffActions: TableAction[] = [
    { key: 'reschedule', label: 'Reschedule' },
    { key: 'cancel', label: 'Cancel', isDanger: true }
  ];

  // Cancel modal state
  showCancelModal: boolean = false;
  cancelTarget: AppointmentDto | null = null;

  // Reschedule modal state (staff only)
  showRescheduleModal: boolean = false;
  rescheduleTarget: AppointmentDto | null = null;
  availableSlots: any[] = [];
  selectedNewSlotId: number | null = null;
  isLoadingSlots: boolean = false;

  constructor(
    private profileService: ProfileService,
    private appointmentService: AppointmentService,
    private toaster: ToasterService,
    private router: Router
  ) {}

  async ngOnInit() {
    await this.profileService.getUserContent();
    this.user = this.profileService.userProfile;
    if (!this.user) return;

    this.isStaff = this.user.isVet || this.user.isNurse
                   || this.user.isBarber || this.user.isMainVet;
    await this.loadAppointments();
  }

  async loadAppointments() {
    this.isLoading = true;
    try {
      if (this.isStaff) {
        this.appointments = await this.appointmentService.getByEmployeeId(this.user!.id);
      } else {
        this.appointments = await this.appointmentService.getByCustomerId(this.user!.id);
      }
    } catch {
      this.appointments = [];
    } finally {
      this.isLoading = false;
    }
  }

  // ── Regular user: filter by selected date ──
  get filteredByDate(): AppointmentDto[] {
    return this.appointments.filter(a => {
      const d = new Date(a.slotDateTime);
      return d.toDateString() === this.selectedDate.toDateString();
    });
  }

  onDateChange(date: Date) {
    this.selectedDate = date;
    this.selectedAppointment = null;
  }

  selectAppointment(appt: AppointmentDto) {
    this.selectedAppointment = appt;
  }

  canCancel(appt: AppointmentDto): boolean {
    if (this.isStaff) return true;
    return this.appointmentService.canCancelAsUser(appt);
  }

  // ── Cancel flow ──
  openCancelModal(appt: AppointmentDto) {
    this.cancelTarget = appt;
    this.showCancelModal = true;
  }

  closeCancelModal() {
    this.showCancelModal = false;
    this.cancelTarget = null;
  }

  async confirmCancel() {
    if (!this.cancelTarget) return;
    try {
      await this.appointmentService.cancel(this.cancelTarget.id);
      this.toaster.success('Cancelled', 'Appointment cancelled successfully.');
      this.closeCancelModal();
      this.selectedAppointment = null;
      await this.loadAppointments();
    } catch {
      this.toaster.error('Error', 'Failed to cancel appointment.');
    }
  }

  // ── Reschedule flow (staff) ──
  async openRescheduleModal(appt: AppointmentDto) {
    this.rescheduleTarget = appt;
    this.selectedNewSlotId = null;
    this.isLoadingSlots = true;
    this.showRescheduleModal = true;

    try {
      const dateStr = appt.slotDateTime.split('T')[0];
      const { data } = await axios.get(
        Config.address + `api/TimeSlot/Get?employeeid=${appt.employeeId}&date=${dateStr}`
      );
      this.availableSlots = Array.isArray(data) ? data : [];
    } catch {
      this.availableSlots = [];
    } finally {
      this.isLoadingSlots = false;
    }
  }

  closeRescheduleModal() {
    this.showRescheduleModal = false;
    this.rescheduleTarget = null;
    this.availableSlots = [];
    this.selectedNewSlotId = null;
  }

  async confirmReschedule() {
    if (!this.rescheduleTarget || !this.selectedNewSlotId) return;
    try {
      await this.appointmentService.reschedule(
        this.rescheduleTarget.id, this.selectedNewSlotId
      );
      this.toaster.success('Rescheduled', 'Appointment rescheduled successfully.');
      this.closeRescheduleModal();
      await this.loadAppointments();
    } catch {
      this.toaster.error('Error', 'Failed to reschedule appointment.');
    }
  }

  // ── Staff table 3-dot menu handler ──
  onStaffAction(event: { action: string; row: any }) {
    const appt = event.row as AppointmentDto;
    if (event.action === 'cancel') {
      this.openCancelModal(appt);
    } else if (event.action === 'reschedule') {
      this.openRescheduleModal(appt);
    }
  }

  // Staff table: format date for display
  get staffTableData(): any[] {
    return this.appointments.map(a => ({
      ...a,
      slotDateTime: new Date(a.slotDateTime).toLocaleDateString('en-US', {
        weekday: 'short', month: 'short', day: 'numeric'
      })
    }));
  }
}
