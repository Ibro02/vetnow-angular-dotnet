import { Component, forwardRef, OnInit } from '@angular/core';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import { VetStationComponent } from '../vet-station/vet-station.component';
import { NgClass, NgFor } from '@angular/common';
import { PageTitleContainerComponent } from "../../components/common/page-title-container/page-title-container.component";
import { ButtonComponent } from "../../components/common/button/button.component";
import axios from 'axios';
import { AddEmployeeComponent } from '../../components/group/add-employee/add-employee.component';

@Component({
  selector: 'app-employee-list',
  standalone: true,
  imports: [NgClass, NgFor, PageTitleContainerComponent, ButtonComponent, AddEmployeeComponent],
  templateUrl: './employee-list.component.html',
  styleUrl: './employee-list.component.css',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      multi: true,
      useExisting: forwardRef(() => VetStationComponent),
    },
  ],
})
export class EmployeeListComponent implements OnInit{
test(a: any) {
console.log(a)
}
employees: any = null;
  exportToCSV(): void {
    const csvData = this.convertToCSV(this.employees);
    const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', 'employees.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  private convertToCSV(objArray: any[]): string {
    const array = [Object.keys(objArray[0])].concat(objArray);

    return array.map(it => {
      return Object.values(it).toString();
    }).join('\n');
  }
  async fetchEmployee() //for now it fetches every person in database
  {

   let { data } = await axios.get("https://localhost:44308/api/Person/GetAll");
   return data;
  }
 
  async ngOnInit(): Promise<void> {
   this.employees = await this.fetchEmployee();
   console.log(this.employees);
  }
}

export interface IEmployee {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  roleId: number | null; //this should be in a title
  birthDate: string;
  username: string;
  password: string;
  city: string | null;
  country: string | null;
  profileCreationDate: string;
  membershipLoyalty: string | null;
}

//@todo - > add new fields in employee DB (status, title), fetch emloyees instead of persons