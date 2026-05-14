import { Component, OnInit } from '@angular/core';
import { NgIf, NgFor } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { MyAuthService } from '../../services/MyAuth';
import { ToasterService } from '../../services/toaster.service';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../../environment';

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

  constructor(
    public auth: MyAuthService,
    private toaster: ToasterService,
    private http: HttpClient,
  ) {}

  async ngOnInit() {
    if (this.auth.isAdminUser()) {
      try {
        this.employees = await firstValueFrom(
          this.http.get<any[]>(`${environment.apiUrl}/api/AdminPanel/Employees`)
        );
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
      await firstValueFrom(
        this.http.post(`${environment.apiUrl}/api/Availability/Add`, {
          employeeId: employeeId,
          availableFrom: '09:00',
          availableTo: '17:00',
          breakFrom: '10:30',
          breakTo: '11:00',
          appointmentDuration: '35',
        })
      );

      this.toaster.success('Success', 'Availability generated successfully!');
      this.generated = true;
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to generate availability');
    } finally {
      this.loading = false;
    }
  }
}
