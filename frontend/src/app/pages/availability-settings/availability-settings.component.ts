import { Component, OnInit } from '@angular/core';
import { NgIf, NgFor } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { MyAuthService } from '../../services/MyAuth';
import { ToasterService } from '../../services/toaster.service';
import axios from 'axios';
import { environment } from '../../../enviroment';

@Component({
  selector: 'app-availability-settings',
  standalone: true,
  imports: [NgIf, NgFor, FormsModule, HeaderTitleComponent],
  templateUrl: './availability-settings.component.html',
  styleUrl: './availability-settings.component.css',
})
export class AvailabilitySettingsComponent implements OnInit {
  loading = false;
  generated = false;

  // Admin employee selection
  employees: any[] = [];
  selectedEmployeeId: number | null = null;

  private get headers() {
    const token = window.localStorage.getItem('my-auth-token') ?? window.sessionStorage.getItem('my-auth-token');
    return { 'my-auth-token': token ?? '' };
  }

  constructor(
    public auth: MyAuthService,
    private toaster: ToasterService,
  ) {}

  async ngOnInit() {
    if (this.auth.isAdminUser()) {
      try {
        const { data } = await axios.get(`${environment.apiUrl}/api/AdminPanel/Employees`, { headers: this.headers });
        this.employees = data;
      } catch {}
    }
  }

  async generateAvailability() {
    let employeeId: number | null;

    if (this.auth.isAdminUser()) {
      employeeId = this.selectedEmployeeId;
      if (!employeeId) {
        this.toaster.error('Error', 'Please select an employee.');
        return;
      }
    } else {
      employeeId = this.auth.userProfile?.employeeId ?? null;
      if (!employeeId) {
        this.toaster.error('Error', 'Employee ID not found. Are you an employee?');
        return;
      }
    }

    this.loading = true;
    try {
      await axios.post(`${environment.apiUrl}/api/Availability/Add`, {
        employeeId: employeeId,
        availableFrom: '09:00',
        availableTo: '17:00',
        breakFrom: '10:30',
        breakTo: '11:00',
        appointmentDuaration: '35',
      }, { headers: this.headers });

      this.toaster.success('Success', 'Availability generated successfully!');
      this.generated = true;
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to generate availability');
    } finally {
      this.loading = false;
    }
  }
}
