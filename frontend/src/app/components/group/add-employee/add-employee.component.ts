import { NgClass, NgStyle } from '@angular/common';
import { Component, OnInit, Output,EventEmitter } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ButtonComponent } from "../../common/button/button.component";
import axios from 'axios';
import { Config } from '../../../config';

@Component({
  selector: 'app-add-employee',
  standalone: true, 
  imports: [NgClass, NgStyle, ReactiveFormsModule, ButtonComponent],
  templateUrl: './add-employee.component.html',
  styleUrls: ['./add-employee.component.css']
})
export class AddEmployeeComponent implements OnInit {
  @Output() event = new EventEmitter<void>();
  employeeForm: FormGroup;
  showModal = false;
 ngOnInit(): void {
 }
  constructor(private fb: FormBuilder) {
    this.employeeForm = this.fb.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', Validators.required],
      roleId: [0, Validators.required],
      birthDate: ['', Validators.required],
      username: ['', Validators.required],
      password: ['', Validators.required],
      city: ['', Validators.required],
      country: ['', Validators.required],
      profileCreationDate: [`${Date.now()}`, Validators.required],
      vetStationId: [1, Validators.required], //temporary -> TODO: make auth-token where vetStationId is stored in local storage
      dateOfEmployment: ['', Validators.required]
    });
  }

  openModal() {
    this.showModal = true;
  }

  closeModal() {
    this.showModal = false;
  }

  onSubmit() {
    if (this.employeeForm.valid) {
      const newEmployee = this.employeeForm.value;
      console.log('New Employee:', newEmployee);
      let url = `${Config.address}api/EmployeeEndpoint/AddNewEmployee`;
  
      // Helper function to validate and convert date strings
      const convertToISO = (dateString: string) => {
        const date = new Date(dateString);
        return isNaN(date.getTime()) ? null : date.toISOString();
      };
      let currentDate: Date = new Date(Date.now());
      // Convert dates to ISO string format, only if they are valid
      newEmployee.birthDate = convertToISO(newEmployee.birthDate);
      newEmployee.dateOfEmployment = convertToISO(newEmployee.dateOfEmployment);
      newEmployee.profileCreationDate = currentDate.toISOString();
  
      // Optionally check if any of the dates are null due to invalid input
      if (!newEmployee.birthDate || !newEmployee.dateOfEmployment || !newEmployee.profileCreationDate) {
        console.error('One or more dates are invalid.');
        return; // Exit the function early if invalid date(s) found
      }
  
      axios.post(url, newEmployee)
        .then((response) => {
          console.log('Response:', response.data);
          this.event.emit();
        })
        .catch((error) => {
          console.error('Error:', error.response ? error.response.data : error.message);
        });
        
        this.closeModal(); 
      }
    }
  
}
