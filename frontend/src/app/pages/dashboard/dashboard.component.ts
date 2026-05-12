import { Component, OnInit } from '@angular/core';
import { NgIf, NgFor, NgClass, DatePipe, DecimalPipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../../enviroment';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { fadeIn, listStagger } from '../../animations/shared.animations';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';
import {
  faUsers, faPaw, faCalendarCheck, faHospital,
  faBoxes, faCalendarDay, faArrowRight, faStethoscope,
  faCut, faSyringe, faChartLine, faRefresh
} from '@fortawesome/free-solid-svg-icons';

interface KpiCard {
  label: string;
  value: number;
  icon: any;
  color: string;
  bgColor: string;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [NgIf, NgFor, NgClass, DatePipe, DecimalPipe, RouterLink, HeaderTitleComponent, FaIconComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css',
  animations: [fadeIn, listStagger],
})
export class DashboardComponent implements OnInit {
  isLoading = true;
  error: string | null = null;

  // Icons
  faArrowRight = faArrowRight;
  faChartLine = faChartLine;
  faRefresh = faRefresh;
  faStethoscope = faStethoscope;
  faCut = faCut;
  faSyringe = faSyringe;

  // KPI
  kpiCards: KpiCard[] = [];

  // Recent appointments
  recentAppointments: any[] = [];

  // Chart data
  appointmentsByDay: { date: string; count: number }[] = [];
  maxAppointmentCount = 1;

  speciesChart: { name: string; count: number }[] = [];
  totalSpeciesCount = 1;

  employeeBreakdown = { vets: 0, nurses: 0, barbers: 0 };
  totalEmployeeBreakdown = 1;

  constructor(private http: HttpClient) {}

  async ngOnInit() {
    await this.loadDashboard();
  }

  async loadDashboard() {
    this.isLoading = true;
    this.error = null;
    try {
      const data: any = await firstValueFrom(
        this.http.get(`${environment.apiUrl}/api/Dashboard/GetStats`)
      );

      const k = data.kpis;
      this.kpiCards = [
        { label: 'Employees',         value: k.totalEmployees,     icon: faUsers,        color: '#33b3ae', bgColor: 'rgba(51,179,174,0.1)' },
        { label: 'Vet Stations',      value: k.totalVetStations,   icon: faHospital,     color: '#3B82F6', bgColor: 'rgba(59,130,246,0.1)' },
        { label: 'Registered Pets',   value: k.totalPets,          icon: faPaw,          color: '#F59E0B', bgColor: 'rgba(245,158,11,0.1)' },
        { label: 'Total Appointments',value: k.totalAppointments,  icon: faCalendarCheck,color: '#10B981', bgColor: 'rgba(16,185,129,0.1)' },
        { label: 'Appointments Today',value: k.appointmentsToday,  icon: faCalendarDay,  color: '#8B5CF6', bgColor: 'rgba(139,92,246,0.1)' },
        { label: 'Inventory Items',   value: k.totalInventoryItems,icon: faBoxes,        color: '#EF4444', bgColor: 'rgba(239,68,68,0.1)' },
      ];

      this.recentAppointments = data.recentAppointments ?? [];

      this.appointmentsByDay = data.appointmentsByDay ?? [];
      this.maxAppointmentCount = Math.max(...this.appointmentsByDay.map(d => d.count), 1);

      this.speciesChart = data.speciesChart ?? [];
      this.totalSpeciesCount = this.speciesChart.reduce((sum, s) => sum + s.count, 0) || 1;

      this.employeeBreakdown = data.employeeBreakdown ?? { vets: 0, nurses: 0, barbers: 0 };
      this.totalEmployeeBreakdown =
        this.employeeBreakdown.vets + this.employeeBreakdown.nurses + this.employeeBreakdown.barbers || 1;

    } catch (err: any) {
      this.error = err.error ?? 'Failed to load dashboard';
    } finally {
      this.isLoading = false;
    }
  }

  getBarHeight(count: number): string {
    return Math.max((count / this.maxAppointmentCount) * 100, 4) + '%';
  }

  getDayLabel(dateStr: string): string {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-US', { weekday: 'short' });
  }

  getSpeciesPercent(count: number): string {
    return ((count / this.totalSpeciesCount) * 100).toFixed(0) + '%';
  }

  getSpeciesBarWidth(count: number): string {
    return ((count / this.totalSpeciesCount) * 100) + '%';
  }

  getBreakdownPercent(val: number): string {
    return ((val / this.totalEmployeeBreakdown) * 100).toFixed(0) + '%';
  }

  speciesColors = ['#33b3ae', '#3FCA93', '#3B82F6', '#F59E0B', '#8B5CF6', '#EF4444'];
}
