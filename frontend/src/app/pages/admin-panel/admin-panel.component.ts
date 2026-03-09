import { Component, OnInit } from '@angular/core';
import { NgIf, NgFor, NgClass } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TableComponent, TableColumn, TableAction } from '../../components/common/table/table.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import axios from 'axios';
import { environment } from '../../../enviroment';
import { ToasterService } from '../../services/toaster.service';

@Component({
  selector: 'app-admin-panel',
  standalone: true,
  imports: [NgIf, NgFor, NgClass, FormsModule, TableComponent, HeaderTitleComponent],
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

  private get headers() {
    const token = window.localStorage.getItem('my-auth-token') ?? window.sessionStorage.getItem('my-auth-token');
    return { 'my-auth-token': token ?? '' };
  }

  constructor(private toaster: ToasterService) {}

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
      const { data } = await axios.get(`${environment.apiUrl}/api/AdminPanel/Users`, {
        params,
        headers: this.headers,
      });
      this.users = data.users;
      this.usersTotalCount = data.totalCount;
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to load users');
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
      if (!confirm(`Delete user "${event.row.username}"?`)) return;
      try {
        await axios.delete(`${environment.apiUrl}/api/AdminPanel/Users/Delete`, {
          params: { id: event.row.id }, headers: this.headers,
        });
        this.toaster.success('Success', 'User deleted');
        await this.loadUsers();
      } catch (err: any) {
        this.toaster.error('Error', err.response?.data ?? 'Failed to delete user');
      }
    }
  }

  openAddUser() {
    this.userForm = { firstName: '', lastName: '', email: '', username: '', password: '', phone: '', city: '', country: '', roleId: 1 };
    this.isNewUser = true;
    this.showUserModal = true;
  }

  async saveUser() {
    try {
      if (this.isNewUser) {
        await axios.post(`${environment.apiUrl}/api/AdminPanel/Users/Add`, this.userForm, { headers: this.headers });
        this.toaster.success('Success', 'User created');
      } else {
        await axios.put(`${environment.apiUrl}/api/AdminPanel/Users/Update`, {
          id: this.userForm.id,
          firstName: this.userForm.firstName,
          lastName: this.userForm.lastName,
          email: this.userForm.email,
          username: this.userForm.username,
          phone: this.userForm.phone,
          city: this.userForm.city,
          country: this.userForm.country,
          roleId: this.userForm.roleId,
        }, { headers: this.headers });
        this.toaster.success('Success', 'User updated');
      }
      this.showUserModal = false;
      await this.loadUsers();
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to save user');
    }
  }

  async saveRole() {
    try {
      await axios.put(`${environment.apiUrl}/api/AdminPanel/Users/Update`, {
        id: this.selectedUser.id, roleId: this.selectedRoleId,
      }, { headers: this.headers });
      this.toaster.success('Success', 'Role updated');
      this.showRoleModal = false;
      await this.loadUsers();
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to update role');
    }
  }

  // ═══════════════════════════════
  // VET STATIONS (list)
  // ═══════════════════════════════

  async loadStations() {
    try {
      const params: any = { page: this.stationsPage, pageSize: this.stationsPageSize };
      if (this.stationsSearch) params.search = this.stationsSearch;
      const { data } = await axios.get(`${environment.apiUrl}/api/AdminPanel/VetStations`, {
        params,
        headers: this.headers,
      });
      this.stations = data.stations;
      this.stationsTotalCount = data.totalCount;
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to load stations');
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
    try {
      if (this.isNewStation) {
        await axios.post(`${environment.apiUrl}/api/AdminPanel/VetStations/Add`, this.stationForm, { headers: this.headers });
        this.toaster.success('Success', 'Vet station created');
      } else {
        await axios.put(`${environment.apiUrl}/api/AdminPanel/VetStations/Update`, this.stationForm, { headers: this.headers });
        this.toaster.success('Success', 'Vet station updated');
      }
      this.showStationModal = false;
      await this.loadStations();
      if (this.showStationDetail && this.stationDetail?.id === this.stationForm.id) {
        await this.openStationDetail(this.stationForm.id);
      }
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to save station');
    }
  }

  async deleteStation(row: any) {
    if (!confirm(`Delete station "${row.name}"?`)) return;
    try {
      await axios.delete(`${environment.apiUrl}/api/AdminPanel/VetStations/Delete`, {
        params: { id: row.id }, headers: this.headers,
      });
      this.toaster.success('Success', 'Vet station deleted');
      this.showStationDetail = false;
      await this.loadStations();
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to delete station');
    }
  }

  // ═══════════════════════════════
  // STATION DETAIL VIEW
  // ═══════════════════════════════

  async openStationDetail(stationId: number) {
    try {
      const { data } = await axios.get(`${environment.apiUrl}/api/AdminPanel/VetStations/Details/${stationId}`, {
        headers: this.headers,
      });
      this.stationDetail = data.station;
      this.stationEmployees = data.employees;
      this.stationMetrics = data.metrics;
      this.stationMainVet = data.mainVet;
      this.showStationDetail = true;
      this.detailTab = 'employees';
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to load station details');
    }
  }

  closeStationDetail() {
    this.showStationDetail = false;
    this.stationDetail = null;
  }

  async onStationEmpAction(event: { action: string; row: any }) {
    if (event.action === 'setMainVet') {
      try {
        await axios.put(`${environment.apiUrl}/api/AdminPanel/VetStations/AssignMainVet`, {
          employeeId: event.row.id, vetStationId: this.stationDetail.id,
        }, { headers: this.headers });
        this.toaster.success('Success', `${event.row.firstName} ${event.row.lastName} set as Main Vet`);
        await this.openStationDetail(this.stationDetail.id);
      } catch (err: any) {
        this.toaster.error('Error', err.response?.data ?? 'Failed to assign main vet');
      }
    } else if (event.action === 'remove') {
      if (!confirm(`Remove ${event.row.firstName} ${event.row.lastName} from this station?`)) return;
      try {
        await axios.put(`${environment.apiUrl}/api/AdminPanel/VetStations/RemoveEmployee`, {
          employeeId: event.row.id, vetStationId: this.stationDetail.id,
        }, { headers: this.headers });
        this.toaster.success('Success', 'Employee removed from station');
        await this.openStationDetail(this.stationDetail.id);
      } catch (err: any) {
        this.toaster.error('Error', err.response?.data ?? 'Failed to remove employee');
      }
    }
  }

  async openAssignEmployee() {
    try {
      const { data } = await axios.get(`${environment.apiUrl}/api/AdminPanel/Employees/Unassigned`, { headers: this.headers });
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
      await axios.put(`${environment.apiUrl}/api/AdminPanel/VetStations/AssignEmployee`, {
        employeeId: this.selectedAssignEmployeeId, vetStationId: this.stationDetail.id,
      }, { headers: this.headers });
      this.toaster.success('Success', 'Employee assigned to station');
      this.showAssignModal = false;
      await this.openStationDetail(this.stationDetail.id);
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to assign employee');
    }
  }

  async createAndAssignEmployee() {
    if (!this.newEmployeeForm.firstName || !this.newEmployeeForm.email || !this.newEmployeeForm.username || !this.newEmployeeForm.password) {
      this.toaster.error('Error', 'Please fill in required fields (name, email, username, password).');
      return;
    }
    try {
      await axios.post(`${environment.apiUrl}/api/AdminPanel/Employees/Add`, {
        ...this.newEmployeeForm,
        vetStationId: this.stationDetail.id,
      }, { headers: this.headers });
      this.toaster.success('Success', 'Employee created and assigned');
      this.showAssignModal = false;
      await this.openStationDetail(this.stationDetail.id);
    } catch (err: any) {
      this.toaster.error('Error', err.response?.data ?? 'Failed to create employee');
    }
  }

  // ─── Roles ───

  async loadRoles() {
    try {
      const { data } = await axios.get(`${environment.apiUrl}/api/AdminPanel/Roles`, { headers: this.headers });
      this.roles = data;
    } catch {}
  }
}
