import { Injectable } from '@angular/core';
import axios from 'axios';
import { Config } from '../config';
import { MyAuthService } from './MyAuth';

export interface AppointmentDto {
  id: number;
  customerId: number | null;
  employeeId: number | null;
  vetStationId: number | null;
  animalId: number | null;
  timeSlotId: number | null;
  slotDateTime: string;
  appointmentTime: string;
  animalName: string | null;
  speciesName: string | null;
  employeeFirstName: string | null;
  employeeLastName: string | null;
  vetStationName: string | null;
  // Staff-only (returned by GetByEmployeeId)
  customerFirstName?: string | null;
  customerLastName?: string | null;
}

@Injectable({ providedIn: 'root' })
export class AppointmentService {

  constructor(private authService: MyAuthService) {}

  private get headers() {
    return { 'my-auth-token': this.authService.token ?? '' };
  }

  async getByCustomerId(customerId: number): Promise<AppointmentDto[]> {
    const { data } = await axios.get(
      Config.address + `api/Appointment/GetByCustomerId?customerId=${customerId}`,
      { headers: this.headers }
    );
    return Array.isArray(data) ? data : [];
  }

  async getByEmployeeId(employeeId: number): Promise<AppointmentDto[]> {
    const { data } = await axios.get(
      Config.address + `api/Appointment/GetByEmployeeId?employeeId=${employeeId}`,
      { headers: this.headers }
    );
    return Array.isArray(data) ? data : [];
  }

  async cancel(appointmentId: number): Promise<void> {
    await axios.delete(
      Config.address + `api/Appointment/Cancel?appointmentId=${appointmentId}`,
      { headers: this.headers }
    );
  }

  async reschedule(appointmentId: number, newTimeSlotId: number): Promise<void> {
    await axios.put(
      Config.address + `api/Appointment/Reschedule`,
      { appointmentId, newTimeSlotId },
      { headers: this.headers }
    );
  }

  /** Returns true if the appointment is >= 48 hours away (cancellable by regular user) */
  canCancelAsUser(appt: AppointmentDto): boolean {
    const slotDate = new Date(appt.slotDateTime);
    // Combine date + appointment time (HH:mm)
    const [h, m] = appt.appointmentTime.split(':').map(Number);
    slotDate.setHours(h, m, 0, 0);

    const diffMs = slotDate.getTime() - Date.now();
    const diffHours = diffMs / (1000 * 60 * 60);
    return diffHours >= 48;
  }
}
