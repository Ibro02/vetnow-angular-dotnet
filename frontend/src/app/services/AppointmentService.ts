import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Subject, firstValueFrom } from 'rxjs';
import { environment } from '../../environment';

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

  /** Emits whenever appointments are modified (cancel, reschedule) */
  changed$ = new Subject<void>();

  constructor(private http: HttpClient) {}

  async getByCustomerId(customerId: number): Promise<AppointmentDto[]> {
    const data = await firstValueFrom(
      this.http.get<AppointmentDto[]>(
        `${environment.apiUrl}/api/Appointment/GetByCustomerId?customerId=${customerId}`
      )
    );
    return Array.isArray(data) ? data : [];
  }

  async getByEmployeeId(employeeId: number): Promise<AppointmentDto[]> {
    const data = await firstValueFrom(
      this.http.get<AppointmentDto[]>(
        `${environment.apiUrl}/api/Appointment/GetByEmployeeId?employeeId=${employeeId}`
      )
    );
    return Array.isArray(data) ? data : [];
  }

  async cancel(appointmentId: number): Promise<void> {
    await firstValueFrom(
      this.http.delete(
        `${environment.apiUrl}/api/Appointment/Cancel?appointmentId=${appointmentId}`,
        { responseType: 'text' }
      )
    );
    this.changed$.next();
  }

  async reschedule(appointmentId: number, newTimeSlotId: number): Promise<void> {
    await firstValueFrom(
      this.http.put(
        `${environment.apiUrl}/api/Appointment/Reschedule`,
        { appointmentId, newTimeSlotId },
        { responseType: 'text' }
      )
    );
    this.changed$.next();
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
