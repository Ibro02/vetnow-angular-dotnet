import { Component, OnInit } from '@angular/core';
import { NgIf } from '@angular/common';
import { TableComponent, TableColumn, TableAction } from '../../components/common/table/table.component';
import { AddEmployeeComponent } from '../../components/group/add-employee/add-employee.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { MyAuthService } from '../../services/MyAuth';
import axios from 'axios';
import {environment} from "../../../enviroment";
import {ToasterService} from "../../services/toaster.service";

@Component({
  selector: 'app-employee-list',
  standalone: true,
  imports: [NgIf, TableComponent, AddEmployeeComponent, HeaderTitleComponent],
  templateUrl: './employee-list.component.html',
  styleUrl: './employee-list.component.css',
})
export class EmployeeListComponent implements OnInit {
  employees: any[] = [];
  showAddEmployee = false;
  editingEmployee: any = null;

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
  ) {}

  async ngOnInit(): Promise<void> {
    const token = window.localStorage.getItem('my-auth-token') ?? window.sessionStorage.getItem('my-auth-token');
    const { data } = await axios.get(`${environment.apiUrl}/api/Employee/GetAllEmployees`, {
      headers: { 'my-auth-token': token }
    });
    this.employees = data.dataItems;
  }

  onAction(event: { action: string; row: any }): void {
    if (!this.auth.isAtLeastMainVet()) return; // extra safety
    if (event.action === 'edit') {
      this.editingEmployee = event.row;
      this.showAddEmployee = true;
    } else if (event.action === 'delete') {
      let url: string = `${environment.apiUrl}/api/Employee/Delete?id=${event.row.id}`;
      const token = window.localStorage.getItem('my-auth-token') ?? window.sessionStorage.getItem('my-auth-token');
      axios.delete(url, { headers: { 'my-auth-token': token } }).then(() => {
        this.toaster.success("Success", "Employee deleted successfully!");
        this.ngOnInit();
      })
        .catch((er) => this.toaster.error("Whops!", `Something went wrong!\n ${er.message}`));
    }
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
