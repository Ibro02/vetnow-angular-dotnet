import { Component, OnInit } from '@angular/core';
import { OtherSignUpMethodsComponent } from "../../components/other-sign-up-methods/other-sign-up-methods.component";
import { SignInInputComponent } from "../../components/common/sign-in-input/sign-in-input.component";
import { PasswordStrengthMeterComponent } from "../../components/common/password-strength-meter/password-strength-meter.component";
import { MyAuthService } from '../../services/MyAuth';
import { HttpClient, HttpErrorResponse } from "@angular/common/http";
import { Router, RouterLink } from "@angular/router";
import { ToasterService } from '../../services/toaster.service';
import { environment } from '../../../environment';
import { shake, fadeIn, slideStep } from '../../animations/shared.animations';

@Component({
    selector: 'app-register',
    standalone: true,
    templateUrl: './register.component.html',
    styleUrl: './register.component.css',
    imports: [
        OtherSignUpMethodsComponent,
        SignInInputComponent,
        PasswordStrengthMeterComponent
    ],
    animations: [shake, fadeIn, slideStep],
})
export class RegisterComponent implements OnInit {

  constructor(
    public router: Router,
    private myAuthService: MyAuthService,
    private toaster: ToasterService,
    private http: HttpClient,
  ) {}

  ngOnInit(): void {}

  /* ─── Wizard state ─── */
  currentStep = 1;
  totalSteps = 2;

  /* ─── Form model ─── */
  public newUser = {
    Email: "",
    Username: "",
    Password: "",
  };

  /* ─── Validation ─── */
  emailRegex = new RegExp('^[\\w\\-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
  passwordRegex = new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^\\da-zA-Z]).{8,128}$');
  usernameRegex = new RegExp('^[a-zA-Z0-9_\\-]{5,30}$');
  isError = false;

  /* ─── Step labels for the progress indicator ─── */
  steps = [
    { label: 'Basic Info', icon: '1' },
    { label: 'Security',   icon: '2' },
  ];

  /* ─── Navigation ─── */
  nextStep(): void {
    if (this.currentStep === 1) {
      // Validate Step 1 fields before proceeding
      if (!this.emailRegex.test(this.newUser.Email)) {
        this.isError = true;
        this.toaster.error('Validation Error', 'Email format is invalid.');
        return;
      }
      if (!this.usernameRegex.test(this.newUser.Username)) {
        this.isError = true;
        this.toaster.error('Validation Error', 'Username must be 5–30 characters (letters, digits, _ or -).');
        return;
      }
    }
    this.isError = false;
    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
    }
  }

  prevStep(): void {
    this.isError = false;
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  /* ─── Registration submit (final step) ─── */
  register = () => {
    if (!this.passwordRegex.test(this.newUser.Password)) {
      this.isError = true;
      this.toaster.error('Validation Error', 'Password must be 8–128 characters with uppercase, lowercase, digit, and special character.');
      return;
    }

    const link = `${environment.apiUrl}/api/Person/Add`;
    this.http.post(link, this.newUser).subscribe({
      next: () => {
        this.router.navigate(['login']);
        this.toaster.success('Registration successful!', 'Please log in with your new account.');
      },
      error: (err: HttpErrorResponse) => {
        if (!err.error?.errors)
          this.toaster.error('Error', err.error);
        else {
          for (const i in err.error?.errors) {
            this.toaster.error('Error', err.error?.errors[i][0]);
          }
        }
      },
    });
  }

  handleValueChanged($event: string, obj: string) {
    //@ts-ignore
    this.newUser[obj] = $event;
  }
}
