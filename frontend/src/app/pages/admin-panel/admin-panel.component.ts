import { Component, OnInit } from '@angular/core';
import { NgIf, NgFor, NgClass } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableComponent, TableColumn, TableAction } from '../../components/common/table/table.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../../enviroment';
import { ToasterService } from '../../services/toaster.service';
import { ConfirmModalComponent } from '../../components/common/confirm-modal/confirm-modal.component';

@Component({
  selector: 'app-admin-panel',
  standalone: true,
  imports: [NgIf, NgFor, NgClass, FormsModule, TableComponent, HeaderTitleComponent, ConfirmModalComponent],
  templateUrl: './admin-panel.component.html',
  styleUrl: './admin-panel.component.css',
})
export class AdminPanelComponent implements OnInit {
  activeTab: 'users' | 'vetstations' = 'users';

  // ─── Users ───
  users: any[] = [];
  usersTotalCount = 0;
  usersPage = 1;
  usersPageSize = 10;
  usersSearch = '';

  userColumns: TableColumn[] = [
    { key: 'firstName', key2: 'lastName', label: 'Name', type: 'avatar', subtitleKey: 'email' },
    { key: 'username', label: 'Username', type: 'text' },
    { key: 'role', label: 'Role', type: 'badge', badgeColorMap: {
      'User': 'badge-default', 'Barber': 'badge-info', 'Nurse': 'badge-info',
      'Vet': 'badge-success', 'MainVet': 'badge-warning', 'Admin': 'badge-danger',
    }},
    { key: 'city', label: 'City', type: 'text' },
    { key: 'phone', label: 'Phone', type: 'text' },
  ];

  userActions: TableAction[] = [
    { key: 'edit', label: 'Edit Profile' },
    { key: 'editRole', label: 'Change Role' },
    { key: 'delete', label: 'Delete', isDanger: true },
  ];

  // ─── Vet Stations ───
  stations: any[] = [];
  stationsTotalCount = 0;
  stationsPage = 1;
  stationsPageSize = 10;
  stationsSearch = '';

  stationColumns: TableColumn[] = [
    { key: 'name', label: 'Name', type: 'text' },
    { key: 'city', label: 'City', type: 'text' },
    { key: 'country', label: 'Country', type: 'text' },
    { key: 'email', label: 'Email', type: 'text' },
    { key: 'contactNumber', label: 'Phone', type: 'text' },
  ];

  stationActions: TableAction[] = [
    { key: 'view', label: 'View Details' },
    { key: 'edit', label: 'Edit' },
    { key: 'delete', label: 'Delete', isDanger: true },
  ];

  // ─── Modals ───
  roles: any[] = [];

  // Role modal
  showRoleModal = false;
  selectedUser: any = null;
  selectedRoleId: number = 1;

  // User edit modal
  showUserModal = false;
  userForm: any = {};
  isNewUser = false;

  // Station edit modal
  showStationModal = false;
  stationForm: any = {};
  isNewStation = false;

  // ─── Station Detail View ───
  showStationDetail = false;
  stationDetail: any = null;
  stationEmployees: any[] = [];
  stationMetrics: any = {};
  stationMainVet: any = null;

  stationEmpColumns: TableColumn[] = [
    { key: 'firstName', key2: 'lastName', label: 'Name', type: 'avatar', subtitleKey: 'email' },
    { key: 'username', label: 'Username', type: 'text' },
    { key: 'role', label: 'Role', type: 'badge', badgeColorMap: {
      'Barber': 'badge-info', 'Nurse': 'badge-info',
      'Vet': 'badge-success', 'MainVet': 'badge-warning',
    }},
    { key: 'city', label: 'City', type: 'text' },
  ];

  stationEmpActions: TableAction[] = [
    { key: 'setMainVet', label: 'Set as Main Vet' },
    { key: 'remove', label: 'Remove from Station', isDanger: true },
  ];

  // Assign employee modal
  showAssignModal = false;
  unassignedEmployees: any[] = [];
  selectedAssignEmployeeId: number | null = null;
  assignMode: 'select' | 'create' = 'select';
  newEmployeeForm: any = {};
  employeeRoles: any[] = [];

  detailTab: 'employees' | 'info' = 'employees';

  // ─── Confirm Modal ───
  showConfirmModal = false;
  confirmTitle = '';
  confirmMessage = '';
  confirmText = 'Confirm';
  confirmIsDanger = true;
  private confirmCallback: (() => void) | null = null;

  constructor(private toaster: ToasterService, private http: HttpClient) {}

  async ngOnInit() {
    await this.loadRoles();
    await this.loadUsers();
  }

  switchTab(tab: 'users' | 'vetstations') {
    this.activeTab = tab;
    this.showStationDetail = false;
    if (tab === 'users') this.loadUsers();
    else this.loadStations();
  }

  // ═══════════════════════════════
  // USERS
  // ═══════════════════════════════

  async loadUsers() {
    try {
      const params: any = { page: this.usersPage, pageSize: this.usersPageSize };
      if (this.usersSearch) params.search = this.usersSearch;
      const data: any = await firstValueFrom(
        this.http.get(`${environment.apiUrl}/api/AdminPanel/Users`, { params })
      );
      this.users = data.users;
      this.usersTotalCount = data.totalCount;
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to load users');
    }
  }

  async onUsersPageChange(event: { pageNumber: number; pageSize: number }) {
    this.usersPage = event.pageNumber;
    this.usersPageSize = event.pageSize;
    await this.loadUsers();
  }

  async onUsersSearch(query: string) {
    this.usersSearch = query;
    this.usersPage = 1;
    await this.loadUsers();
  }

  async onUserAction(event: { action: string; row: any }) {
    if (event.action === 'edit') {
      this.userForm = { ...event.row };
      this.isNewUser = false;
      this.showUserModal = true;
    } else if (event.action === 'editRole') {
      this.selectedUser = event.row;
      this.selectedRoleId = event.row.roleId ?? 1;
      this.showRoleModal = true;
    } else if (event.action === 'delete') {
      this.openConfirm(
        'Delete User',
        `Are you sure you want to delete user "${event.row.username}"? This action cannot be undone.`,
        'Delete',
        true,
        async () => {
          try {
            await firstValueFrom(
              this.http.delete(`${environment.apiUrl}/api/AdminPanel/Users/Delete`, { params: { id: event.row.id }, responseType: 'text' })
            );
            this.toaster.success('Success', 'User deleted');
            await this.loadUsers();
          } catch (err: any) {
            this.toaster.error('Error', err.error ?? 'Failed to delete user');
          }
        }
      );
    }
  }

  openAddUser() {
    this.userForm = { firstName: '', lastName: '', email: '', username: '', password: '', phone: '', city: '', country: '', roleId: 1 };
    this.isNewUser = true;
    this.showUserModal = true;
  }

  async saveUser() {
    if (this.isNewUser) {
      const _emailRx    = /^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
      const _usernameRx = /^[a-zA-Z0-9_\-]{5,30}$/;
      const _passwordRx = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,128}$/;
      const _nameRx     = /^[a-zA-Z\u00C0-\u024F\s'\-]+$/;

      if (!this.userForm.firstName?.trim() || !_nameRx.test(this.userForm.firstName)) {
        this.toaster.error('Validation Error', 'First name is required and must contain only letters.');
        return;
      }
      if (!this.userForm.lastName?.trim() || !_nameRx.test(this.userForm.lastName)) {
        this.toaster.error('Validation Error', 'Last name is required and must contain only letters.');
        return;
      }
      if (!_emailRx.test(this.userForm.email)) {
        this.toaster.error('Validation Error', 'Email format is invalid.');
        return;
      }
      if (!_usernameRx.test(this.userForm.username)) {
        this.toaster.error('Validation Error', 'Username must be 5–30 characters (letters, digits, _ or -).');
        return;
      }
      if (!_passwordRx.test(this.userForm.password)) {
        this.toaster.error('Validation Error', 'Password must be 8–128 characters with uppercase, lowercase, digit, and special character.');
        return;
      }
    }
    try {
      if (this.isNewUser) {
        await firstValueFrom(
          this.http.post(`${environment.apiUrl}/api/AdminPanel/Users/Add`, this.userForm)
        );
        this.toaster.success('Success', 'User created');
      } else {
        await firstValueFrom(
          this.http.put(`${environment.apiUrl}/api/AdminPanel/Users/Update`, {
            id: this.userForm.id,
            firstName: this.userForm.firstName,
            lastName: this.userForm.lastName,
            email: this.userForm.email,
            username: this.userForm.username,
            phone: this.userForm.phone,
            city: this.userForm.city,
            country: this.userForm.country,
            roleId: this.userForm.roleId,
          })
        );
        this.toaster.success('Success', 'User updated');
      }
      this.showUserModal = false;
      await this.loadUsers();
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to save user');
    }
  }

  async saveRole() {
    try {
      await firstValueFrom(
        this.http.put(`${environment.apiUrl}/api/AdminPanel/Users/Update`, {
          id: this.selectedUser.id, roleId: this.selectedRoleId,
        })
      );
      this.toaster.success('Success', 'Role updated');
      this.showRoleModal = false;
      await this.loadUsers();
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to update role');
    }
  }

  // ═══════════════════════════════
  // VET STATIONS (list)
  // ═══════════════════════════════

  async loadStations() {
    try {
      const params: any = { page: this.stationsPage, pageSize: this.stationsPageSize };
      if (this.stationsSearch) params.search = this.stationsSearch;
      const data: any = await firstValueFrom(
        this.http.get(`${environment.apiUrl}/api/AdminPanel/VetStations`, { params })
      );
      this.stations = data.stations;
      this.stationsTotalCount = data.totalCount;
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to load stations');
    }
  }

  async onStationsPageChange(event: { pageNumber: number; pageSize: number }) {
    this.stationsPage = event.pageNumber;
    this.stationsPageSize = event.pageSize;
    await this.loadStations();
  }

  async onStationsSearch(query: string) {
    this.stationsSearch = query;
    this.stationsPage = 1;
    await this.loadStations();
  }

  onStationAction(event: { action: string; row: any }) {
    if (event.action === 'view') {
      this.openStationDetail(event.row.id);
    } else if (event.action === 'edit') {
      this.stationForm = { ...event.row };
      this.isNewStation = false;
      this.showStationModal = true;
    } else if (event.action === 'delete') {
      this.deleteStation(event.row);
    }
  }

  openAddStation() {
    this.stationForm = { name: '', city: '', country: '', email: '', contactNumber: '', address: '', description: '' };
    this.isNewStation = true;
    this.showStationModal = true;
  }

  async saveStation() {
    if (this.isNewStation) {
      const _emailRx = /^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
      const _phoneRx = /^\+?[\d\s\-()\.\+]{7,15}$/;

      if (!this.stationForm.name?.trim() || this.stationForm.name.trim().length < 2) {
        this.toaster.error('Validation Error', 'Station name must be at least 2 characters.');
        return;
      }
      if (!this.stationForm.address?.trim()) {
        this.toaster.error('Validation Error', 'Address is required.');
        return;
      }
      if (this.stationForm.email && !_emailRx.test(this.stationForm.email)) {
        this.toaster.error('Validation Error', 'Email format is invalid.');
        return;
      }
      if (this.stationForm.contactNumber && !_phoneRx.test(this.stationForm.contactNumber)) {
        this.toaster.error('Validation Error', 'Contact number format is invalid.');
        return;
      }
    }
    try {
      if (this.isNewStation) {
        await firstValueFrom(
          this.http.post(`${environment.apiUrl}/api/AdminPanel/VetStations/Add`, this.stationForm)
        );
        this.toaster.success('Success', 'Vet station created');
      } else {
        await firstValueFrom(
          this.http.put(`${environment.apiUrl}/api/AdminPanel/VetStations/Update`, this.stationForm)
        );
        this.toaster.success('Success', 'Vet station updated');
      }
      this.showStationModal = false;
      await this.loadStations();
      if (this.showStationDetail && this.stationDetail?.id === this.stationForm.id) {
        await this.openStationDetail(this.stationForm.id);
      }
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to save station');
    }
  }

  async deleteStation(row: any) {
    this.openConfirm(
      'Delete Vet Station',
      `Are you sure you want to delete station "${row.name}"? This action cannot be undone.`,
      'Delete',
      true,
      async () => {
        try {
          await firstValueFrom(
            this.http.delete(`${environment.apiUrl}/api/AdminPanel/VetStations/Delete`, { params: { id: row.id }, responseType: 'text' })
          );
          this.toaster.success('Success', 'Vet station deleted');
          this.showStationDetail = false;
          await this.loadStations();
        } catch (err: any) {
          this.toaster.error('Error', err.error ?? 'Failed to delete station');
        }
      }
    );
  }

  // ═══════════════════════════════
  // STATION DETAIL VIEW
  // ═══════════════════════════════

  async openStationDetail(stationId: number) {
    try {
      const data: any = await firstValueFrom(
        this.http.get(`${environment.apiUrl}/api/AdminPanel/VetStations/Details/${stationId}`)
      );
      this.stationDetail = data.station;
      this.stationEmployees = data.employees;
      this.stationMetrics = data.metrics;
      this.stationMainVet = data.mainVet;
      this.showStationDetail = true;
      this.detailTab = 'employees';
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to load station details');
    }
  }

  closeStationDetail() {
    this.showStationDetail = false;
    this.stationDetail = null;
  }

  async onStationEmpAction(event: { action: string; row: any }) {
    if (event.action === 'setMainVet') {
      try {
        await firstValueFrom(
          this.http.put(`${environment.apiUrl}/api/AdminPanel/VetStations/AssignMainVet`, {
            employeeId: event.row.id, vetStationId: this.stationDetail.id,
          }, { responseType: 'text' })
        );
        this.toaster.success('Success', `${event.row.firstName} ${event.row.lastName} set as Main Vet`);
        await this.openStationDetail(this.stationDetail.id);
      } catch (err: any) {
        this.toaster.error('Error', err.error ?? 'Failed to assign main vet');
      }
    } else if (event.action === 'remove') {
      this.openConfirm(
        'Remove Employee',
        `Are you sure you want to remove ${event.row.firstName} ${event.row.lastName} from this station?`,
        'Remove',
        true,
        async () => {
          try {
            await firstValueFrom(
              this.http.put(`${environment.apiUrl}/api/AdminPanel/VetStations/RemoveEmployee`, {
                employeeId: event.row.id, vetStationId: this.stationDetail.id,
              }, { responseType: 'text' })
            );
            this.toaster.success('Success', 'Employee removed from station');
            await this.openStationDetail(this.stationDetail.id);
          } catch (err: any) {
            this.toaster.error('Error', err.message ?? 'Failed to remove employee');
          }
        }
      );
    }
  }

  async openAssignEmployee() {
    try {
      const data: any = await firstValueFrom(
        this.http.get(`${environment.apiUrl}/api/AdminPanel/Employees/Unassigned`)
      );
      this.unassignedEmployees = data;
      this.selectedAssignEmployeeId = null;
      this.assignMode = 'select';
      this.employeeRoles = this.roles.filter(r => [2, 3, 4].includes(r.id));
      this.newEmployeeForm = { firstName: '', lastName: '', email: '', username: '', password: '', phone: '', city: '', country: '', roleId: 4 };
      this.showAssignModal = true;
    } catch (err: any) {
      this.toaster.error('Error', 'Failed to load unassigned employees');
    }
  }

  async assignEmployee() {
    if (!this.selectedAssignEmployeeId) {
      this.toaster.error('Error', 'Please select an employee.');
      return;
    }
    try {
      await firstValueFrom(
        this.http.put(`${environment.apiUrl}/api/AdminPanel/VetStations/AssignEmployee`, {
          employeeId: this.selectedAssignEmployeeId, vetStationId: this.stationDetail.id,
        }, { responseType: 'text' })
      );
      this.toaster.success('Success', 'Employee assigned to station');
      this.showAssignModal = false;
      await this.openStationDetail(this.stationDetail.id);
    } catch (err: any) {
      this.toaster.error('Error', err.message ?? 'Failed to assign employee');
    }
  }

  async createAndAssignEmployee() {
    const _emailRx    = /^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
    const _usernameRx = /^[a-zA-Z0-9_\-]{5,30}$/;
    const _passwordRx = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,128}$/;
    const _nameRx     = /^[a-zA-Z\u00C0-\u024F\s'\-]+$/;

    if (!this.newEmployeeForm.firstName?.trim() || !_nameRx.test(this.newEmployeeForm.firstName)) {
      this.toaster.error('Validation Error', 'First name is required and must contain only letters.');
      return;
    }
    if (!this.newEmployeeForm.lastName?.trim() || !_nameRx.test(this.newEmployeeForm.lastName)) {
      this.toaster.error('Validation Error', 'Last name is required and must contain only letters.');
      return;
    }
    if (!_emailRx.test(this.newEmployeeForm.email)) {
      this.toaster.error('Validation Error', 'Email format is invalid.');
      return;
    }
    if (!_usernameRx.test(this.newEmployeeForm.username)) {
      this.toaster.error('Validation Error', 'Username must be 5–30 characters (letters, digits, _ or -).');
      return;
    }
    if (!_passwordRx.test(this.newEmployeeForm.password)) {
      this.toaster.error('Validation Error', 'Password must be 8–128 characters with uppercase, lowercase, digit, and special character.');
      return;
    }
    try {
      await firstValueFrom(
        this.http.post(`${environment.apiUrl}/api/AdminPanel/Employees/Add`, {
          ...this.newEmployeeForm,
          vetStationId: this.stationDetail.id,
        })
      );
      this.toaster.success('Success', 'Employee created and assigned');
      this.showAssignModal = false;
      await this.openStationDetail(this.stationDetail.id);
    } catch (err: any) {
      this.toaster.error('Error', err.error ?? 'Failed to create employee');
    }
  }

  // ─── Roles ───

  async loadRoles() {
    try {
      this.roles = await firstValueFrom(
        this.http.get<any[]>(`${environment.apiUrl}/api/AdminPanel/Roles`)
      );
    } catch {}
  }

  // ─── Confirm Modal helpers ───

  private openConfirm(title: string, message: string, confirmText: string, isDanger: boolean, callback: () => void) {
    this.confirmTitle = title;
    this.confirmMessage = message;
    this.confirmText = confirmText;
    this.confirmIsDanger = isDanger;
    this.confirmCallback = callback;
    this.showConfirmModal = true;
  }

  onConfirmAccept() {
    this.showConfirmModal = false;
    this.confirmCallback?.();
    this.confirmCallback = null;
  }

  onConfirmCancel() {
    this.showConfirmModal = false;
    this.confirmCallback = null;
  }
}
