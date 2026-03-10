import { NgClass, NgStyle } from '@angular/common';
import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  ValidationErrors,
  ValidatorFn,
  Validators,
} from '@angular/forms';
import { ButtonComponent } from "../../common/button/button.component";
import { ToasterService } from '../../../services/toaster.service';
import axios from 'axios';
import { Config } from '../../../config';

/** Birth date must be in the past and the employee must be at least 18 years old. */
function birthDateValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (!control.value) return null;
    const date = new Date(control.value);
    if (isNaN(date.getTime())) return { invalidDate: true };
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (date >= today) return { futureDate: true };
    const minDate = new Date(today);
    minDate.setFullYear(today.getFullYear() - 18);
    if (date > minDate) return { tooYoung: true };
    return null;
  };
}

@Component({
  selector: 'app-add-employee',
  standalone: true,
  imports: [NgClass, NgStyle, ReactiveFormsModule, ButtonComponent],
  templateUrl: './add-employee.component.html',
  styleUrls: ['./add-employee.component.css'],
})
export class AddEmployeeComponent implements OnInit {
  @Output() event = new EventEmitter<void>();

  employeeForm: FormGroup;
  showModal = false;

  ngOnInit(): void {}

  constructor(private fb: FormBuilder, private toaster: ToasterService) {
    this.employeeForm = this.fb.group({
      firstName:           ['', [Validators.required, Validators.maxLength(50),
                                  Validators.pattern(/^[a-zA-Z\u00C0-\u024F\s'\-]+$/)]],
      lastName:            ['', [Validators.required, Validators.maxLength(50),
                                  Validators.pattern(/^[a-zA-Z\u00C0-\u024F\s'\-]+$/)]],
      email:               ['', [Validators.required, Validators.email, Validators.maxLength(254)]],
      phone:               ['', [Validators.required, Validators.pattern(/^\+?[\d\s\-()\.\+]{7,15}$/)]],
      roleId:              [0,  [Validators.required, Validators.min(1)]],
      birthDate:           ['', [Validators.required, birthDateValidator()]],
      username:            ['', [Validators.required, Validators.minLength(5),
                                  Validators.maxLength(30), Validators.pattern(/^[a-zA-Z0-9_\-]+$/)]],
      password:            ['', [Validators.required, Validators.minLength(8),
                                  Validators.maxLength(128),
                                  Validators.pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$/)]],
      city:                ['', Validators.required],
      country:             ['', Validators.required],
      profileCreationDate: [`${Date.now()}`, Validators.required],
      vetStationId:        [1, Validators.required], // TODO: read from auth token
      dateOfEmployment:    ['', Validators.required],
    });
  }

  /** Returns true when the field has been touched AND is invalid — drives the red border. */
  isInvalid(field: string): boolean {
    const ctrl = this.employeeForm.get(field);
    return !!(ctrl && ctrl.invalid && ctrl.touched);
  }

  openModal(): void {
    this.showModal = true;
  }

  closeModal(): void {
    this.showModal = false;
    this.employeeForm.reset({
      profileCreationDate: `${Date.now()}`,
      vetStationId: 1,
      roleId: 0,
    });
  }

  onSubmit(): void {
    if (this.employeeForm.invalid) {
      this.employeeForm.markAllAsTouched();
      this.showFrontendErrors();
      return;
    }

    const newEmployee = { ...this.employeeForm.value };

    const convertToISO = (ds: string): string | null => {
      const d = new Date(ds);
      return isNaN(d.getTime()) ? null : d.toISOString();
    };

    newEmployee.birthDate         = convertToISO(newEmployee.birthDate);
    newEmployee.dateOfEmployment  = convertToISO(newEmployee.dateOfEmployment);
    newEmployee.profileCreationDate = new Date().toISOString();

    if (!newEmployee.birthDate || !newEmployee.dateOfEmployment) {
      this.toaster.error('Validation Error', 'One or more date fields are invalid.');
      return;
    }

    const url = `${Config.address}api/EmployeeEndpoint/AddNewEmployee`;
    axios.post(url, newEmployee)
      .then(() => {
        this.toaster.success('Success', 'Employee added successfully.');
        this.event.emit();
        this.closeModal();
      })
      .catch((error) => {
        // Backend returns semicolon-separated error messages — show each as its own toast.
        const raw: string = error.response?.data ?? error.message ?? 'An unexpected error occurred.';
        raw.split(';')
           .map((s: string) => s.trim())
           .filter(Boolean)
           .forEach((msg: string) => this.toaster.error('Validation Error', msg));
      });
  }

  private showFrontendErrors(): void {
    const fieldMessages: [string, string][] = [
      ['firstName',        'First name is required and must contain only letters (max 50 chars).'],
      ['lastName',         'Last name is required and must contain only letters (max 50 chars).'],
      ['email',            'A valid email address is required (max 254 chars).'],
      ['phone',            'Phone must be 7–15 digits, e.g. +387 61 123 456.'],
      ['roleId',           'A valid role ID (greater than 0) must be entered.'],
      ['birthDate',        'Birth date is required; the employee must be at least 18 years old.'],
      ['username',         'Username must be 5–30 characters: letters, digits, _ or -.'],
      ['password',         'Password must be 8–128 characters with at least one uppercase letter, one lowercase letter, one digit, and one special character.'],
      ['city',             'City is required.'],
      ['country',          'Country is required.'],
      ['dateOfEmployment', 'Date of employment is required.'],
    ];

    fieldMessages.forEach(([field, msg]) => {
      if (this.employeeForm.get(field)?.invalid) {
        this.toaster.error('Validation Error', msg);
      }
    });
  }
}
