import { Component, OnInit } from '@angular/core';
import { NgIf } from '@angular/common';
import { TableComponent, TableColumn, TableAction } from '../../components/common/table/table.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import {
  DynamicFormCardComponent,
  DynamicFormConfig,
} from '../../components/group/pet-add-card/pet-add-card.component';
import { MyAuthService } from '../../services/MyAuth';
import { ToasterService } from '../../services/toaster.service';
import { Config } from '../../config';
import axios from 'axios';

interface PagedResponse<T> {
  dataItems: T[];
  currentPage: number;
  pageSize: number;
  totalCount: number;
}

@Component({
  selector: 'app-employee-list',
  standalone: true,
  imports: [NgIf, TableComponent, HeaderTitleComponent, DynamicFormCardComponent],
  templateUrl: './employee-list.component.html',
  styleUrl: './employee-list.component.css',
})
export class EmployeeListComponent implements OnInit {
  employees: any[] = [];

  // Pagination
  currentPage: number = 1;
  pageSize: number = 10;
  totalCount: number = 0;
  private activeSearchQuery: string = '';

  // Employee form popup
  showEmployeeForm: boolean = false;
  editingEmployeeData: Record<string, any> | null = null;
  employeeFormConfig?: DynamicFormConfig;

  columns: TableColumn[] = [
    {
      key: 'firstName',
      key2: 'lastName',
      label: 'Name',
      type: 'avatar',
      subtitleKey: 'email',
    },
    { key: 'username', label: 'Username', type: 'text' },
    { key: 'phone', label: 'Phone', type: 'text' },
    {
      key: 'role',
      label: 'Role',
      type: 'badge',
      badgeColorMap: {
        'Barber': 'badge-default',
        'Nurse': 'badge-blue',
        'Vet': 'badge-green',
        'MainVet': 'badge-purple',
      },
    },
    { key: 'city', label: 'City', type: 'text' },
    { key: 'country', label: 'Country', type: 'text' },
  ];

  get actions(): TableAction[] {
    if (this.auth.isAtLeastMainVet()) {
      return [
        { key: 'edit', label: 'Edit' },
        { key: 'delete', label: 'Delete', isDanger: true },
      ];
    }
    return [];
  }

  get addBtnText(): string | undefined {
    return this.auth.isAtLeastMainVet() ? 'Add Employee' : undefined;
  }

  constructor(
    public toaster: ToasterService,
    public auth: MyAuthService,
  ) {}

  async ngOnInit(): Promise<void> {
    this.buildFormConfig();
    await this.fetchEmployees();
  }

  private buildFormConfig(): void {
    const today = new Date().toISOString().split('T')[0];
    const minBirthDate = new Date();
    minBirthDate.setFullYear(minBirthDate.getFullYear() - 100);
    const maxBirthDate = new Date();
    maxBirthDate.setFullYear(maxBirthDate.getFullYear() - 18);

    // Employee role IDs: Barber=2, Nurse=3, Vet=4, MainVet=5
    const employeeRoleIds = [2, 3, 4, 5];

    this.employeeFormConfig = {
      title: 'Add New Employee',
      editTitle: 'Edit Employee',
      showPhoto: false,
      gridColumns: 2,
      fields: [
        { key: 'firstName', label: 'First Name', type: 'text', required: true, placeholder: 'Enter first name' },
        { key: 'lastName', label: 'Last Name', type: 'text', required: true, placeholder: 'Enter last name' },
        { key: 'email', label: 'Email', type: 'text', required: true, placeholder: 'Enter email address' },
        { key: 'phone', label: 'Phone', type: 'text', required: true, placeholder: '+387 61 123 456' },
        {
          key: 'roleId',
          label: 'Role',
          type: 'dropdown',
          required: true,
          loadOptions: async () => {
            const { data } = await axios.get<any[]>(
              Config.address + 'api/AdminPanel/Roles',
              { headers: { 'my-auth-token': this.auth.token ?? '' } }
            );
            return data
              .filter((r: any) => employeeRoleIds.includes(r.id))
              .map((r: any) => ({ id: r.id, name: r.name }));
          },
        },
        { key: 'username', label: 'Username', type: 'text', required: true, placeholder: 'Enter username' },
        { key: 'password', label: 'Password', type: 'password', required: true, placeholder: 'Enter password' },
        {
          key: 'birthDate',
          label: 'Birth Date',
          type: 'date',
          required: true,
          maxDate: maxBirthDate.toISOString().split('T')[0],
          minDate: minBirthDate.toISOString().split('T')[0],
        },
        { key: 'city', label: 'City', type: 'text', required: true, placeholder: 'Enter city' },
        { key: 'country', label: 'Country', type: 'text', required: true, placeholder: 'Enter country' },
        {
          key: 'dateOfEmployment',
          label: 'Date of Employment',
          type: 'date',
          required: true,
          maxDate: today,
        },
      ],
    };
  }

  async fetchEmployees(
    search: string = '',
    page: number = 1,
    pageSize: number = this.pageSize,
  ): Promise<void> {
    try {
      const params: Record<string, string | number> = { page, pageSize };
      if (search) params['search'] = search;

      const queryString = Object.entries(params)
        .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
        .join('&');

      const { data } = await axios.get<PagedResponse<any>>(
        `${Config.address}api/Employee/GetAllEmployees?${queryString}`
      );

      this.employees = data.dataItems;
      this.totalCount = data.totalCount;
      this.currentPage = data.currentPage;
      this.pageSize = data.pageSize;
    } catch (error) {
      console.error('Failed to fetch employees:', error);
    }
  }

  onPageChange(event: { pageNumber: number; pageSize: number }): void {
    this.currentPage = event.pageNumber;
    this.pageSize = event.pageSize;
    this.fetchEmployees(this.activeSearchQuery, event.pageNumber, event.pageSize);
  }

  onSearchChange(query: string): void {
    this.activeSearchQuery = query;
    this.currentPage = 1;
    this.fetchEmployees(query, 1, this.pageSize);
  }

  onAddClick(): void {
    this.editingEmployeeData = null;
    this.showEmployeeForm = true;
  }

  onAction(event: { action: string; row: any }): void {
    if (!this.auth.isAtLeastMainVet()) return;

    if (event.action === 'edit') {
      const emp = event.row;
      let formattedBirthDate = '';
      if (emp.birthDate) {
        const d = new Date(emp.birthDate);
        formattedBirthDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      }
      let formattedEmploymentDate = '';
      if (emp.dateOfEmployment) {
        const d = new Date(emp.dateOfEmployment);
        formattedEmploymentDate = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      }

      this.editingEmployeeData = {
        id: emp.id,
        firstName: emp.firstName,
        lastName: emp.lastName,
        email: emp.email,
        phone: emp.phone,
        roleId: emp.roleId,
        username: emp.username,
        birthDate: formattedBirthDate,
        city: emp.city,
        country: emp.country,
        dateOfEmployment: formattedEmploymentDate,
      };
      this.showEmployeeForm = true;
    } else if (event.action === 'delete') {
      const token = window.localStorage.getItem('my-auth-token') ?? window.sessionStorage.getItem('my-auth-token');
      axios.delete(`${Config.address}api/Employee/Delete?id=${event.row.id}`, {
        headers: { 'my-auth-token': token },
      })
        .then(() => {
          this.toaster.success('Success', 'Employee deleted successfully!');
          this.fetchEmployees(this.activeSearchQuery, this.currentPage, this.pageSize);
        })
        .catch((er) => this.toaster.error('Whoops!', `Something went wrong!\n ${er.message}`));
    }
  }

  async onEmployeeSave(formData: Record<string, any>): Promise<void> {
    try {
      const requestBody: any = {
        firstName: formData['firstName'],
        lastName: formData['lastName'],
        email: formData['email'],
        phone: formData['phone'],
        roleId: formData['roleId'],
        username: formData['username'],
        password: formData['password'],
        birthDate: formData['birthDate'] ? new Date(formData['birthDate']).toISOString() : null,
        city: formData['city'],
        country: formData['country'],
        dateOfEmployment: formData['dateOfEmployment'] ? new Date(formData['dateOfEmployment']).toISOString() : null,
        profileCreationDate: new Date().toISOString(),
        vetStationId: this.auth.userProfile?.vetStationId ?? 1,
      };

      await axios.post(
        `${Config.address}api/EmployeeEndpoint/AddNewEmployee`,
        requestBody
      );

      this.toaster.success('Success', 'Employee added successfully.');
      this.showEmployeeForm = false;
      this.editingEmployeeData = null;
      await this.fetchEmployees(this.activeSearchQuery, this.currentPage, this.pageSize);
    } catch (error: any) {
      const raw: string = error.response?.data ?? error.message ?? 'An unexpected error occurred.';
      raw.split(';')
        .map((s: string) => s.trim())
        .filter(Boolean)
        .forEach((msg: string) => this.toaster.error('Validation Error', msg));
    }
  }

  onEmployeeCancel(): void {
    this.showEmployeeForm = false;
    this.editingEmployeeData = null;
  }
}
