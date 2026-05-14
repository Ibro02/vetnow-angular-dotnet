import { Component, OnInit } from '@angular/core';
import { NgIf } from '@angular/common';
import { TableComponent, TableColumn, TableAction } from '../../components/common/table/table.component';
import { AddEmployeeComponent } from '../../components/group/add-employee/add-employee.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { ConfirmModalComponent } from '../../components/common/confirm-modal/confirm-modal.component';
import { MyAuthService } from '../../services/MyAuth';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import {environment} from "../../../enviroment";
import {ToasterService} from "../../services/toaster.service";

@Component({
  selector: 'app-employee-list',
  standalone: true,
  imports: [NgIf, TableComponent, AddEmployeeComponent, HeaderTitleComponent, ConfirmModalComponent],
  templateUrl: './employee-list.component.html',
  styleUrl: './employee-list.component.css',
})
export class EmployeeListComponent implements OnInit {
  employees: any[] = [];
  showAddEmployee = false;
  editingEmployee: any = null;

  // Confirm modal state
  showDeleteConfirm = false;
  deleteTargetEmployee: any = null;

  columns: TableColumn[] = [
    {
      key: 'firstName',
      key2: 'lastName',
      label: 'Name',
      type: 'avatar',
      subtitleKey: 'email',
    },
    { key: 'username', label: 'Username', type: 'text' },
    { key: 'phone',    label: 'Phone',    type: 'text' },
    { key: 'city',     label: 'City',     type: 'text' },
    { key: 'country',  label: 'Country',  type: 'text' },
  ];

  /** MainVet+ gets edit/delete actions; Employee level gets empty (readonly) */
  get actions(): TableAction[] {
    if (this.auth.isAtLeastMainVet()) {
      return [
        { key: 'edit', label: 'Edit' },
        { key: 'delete', label: 'Delete', isDanger: true },
      ];
    }
    return []; // readonly for Employee
  }

  /** Only MainVet+ can add employees */
  get addBtnText(): string | undefined {
    return this.auth.isAtLeastMainVet() ? 'Add Employee' : undefined;
  }

  constructor(
    public toaster: ToasterService,
    public auth: MyAuthService,
    private http: HttpClient,
  ) {}

  async ngOnInit(): Promise<void> {
    const data: any = await firstValueFrom(
      this.http.get(`${environment.apiUrl}/api/Employee/GetAllEmployees`)
    );
    this.employees = data.dataItems;
  }

  onAction(event: { action: string; row: any }): void {
    if (!this.auth.isAtLeastMainVet()) return; // extra safety
    if (event.action === 'edit') {
      this.editingEmployee = event.row;
      this.showAddEmployee = true;
    } else if (event.action === 'delete') {
      this.deleteTargetEmployee = event.row;
      this.showDeleteConfirm = true;
    }
  }

  async confirmDeleteEmployee(): Promise<void> {
    if (!this.deleteTargetEmployee) return;
    this.showDeleteConfirm = false;
    const url = `${environment.apiUrl}/api/Employee/Delete?id=${this.deleteTargetEmployee.id}`;
    this.http.delete(url, { responseType: 'text' }).subscribe({
      next: () => {
        this.toaster.success('Success', 'Employee deleted successfully!');
        this.ngOnInit();
      },
      error: (er) => this.toaster.error('Error', 'Failed to delete employee.'),
    });
    this.deleteTargetEmployee = null;
  }

  cancelDeleteEmployee(): void {
    this.showDeleteConfirm = false;
    this.deleteTargetEmployee = null;
  }
}

export interface IEmployee {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  roleId: number | null;
  birthDate: string;
  username: string;
  password: string;
  city: string | null;
  country: string | null;
  profileCreationDate: string;
  membershipLoyalty: string | null;
}
