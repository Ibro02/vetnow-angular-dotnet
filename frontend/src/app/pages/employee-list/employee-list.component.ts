import { Component, OnInit } from '@angular/core';
import { NgIf } from '@angular/common';
import { TableComponent, TableColumn } from '../../components/common/table/table.component';
import { AddEmployeeComponent } from '../../components/group/add-employee/add-employee.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import axios from 'axios';
import {environment} from "../../../enviroment";
import {provideToastr} from "ngx-toastr";
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

  constructor(public toaster:ToasterService) {
  }
  async ngOnInit(): Promise<void> {
    const { data } = await axios.get(`${environment.apiUrl}/api/Person/GetAll`);
    this.employees = data;
  }

  onAction(event: { action: string; row: any }): void {
    if (event.action === 'edit') {
      console.log('Edit employee:', event.row);
    } else if (event.action === 'delete') {
      let url:string = `${environment.apiUrl}/api/Employee/Delete?id=${event.row.id}`;
      axios.delete(url, {headers:{
          'my-auth-token': (window.sessionStorage.getItem('my-auth-token'))
        }}).then(()=> {
        this.toaster.success("Success", "Employee deleted successefully!");
        this.ngOnInit();
      })
        .catch((er) => this.toaster.error("Whops!", `Something went wrong!\n ${er.message}`));
      console.log('Delete employee:', event.row);
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
