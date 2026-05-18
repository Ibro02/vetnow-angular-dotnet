import { Component, OnInit } from '@angular/core';
import {InputComponent} from "../../components/common/input/input.component";
import { HttpClient } from "@angular/common/http";
import { environment } from '../../../environment';
import {ActivatedRoute, Router} from "@angular/router";
import {ButtonComponent} from "../../components/common/button/button.component";
import {FormsModule} from "@angular/forms";
import {TitleComponent} from "../../components/common/title/title.component";
import {ToasterService} from "../../services/toaster.service";

@Component({
  selector: 'app-verification-page',
  standalone: true,
  imports: [
    InputComponent,
    ButtonComponent,
    FormsModule,
    TitleComponent
  ],
  templateUrl: './verification-page.component.html',
  styleUrl: './verification-page.component.css'
})
export class VerificationPageComponent implements OnInit {
  token: string = "";
  private userId: number | null = null;

  constructor(
    public router: Router,
    private route: ActivatedRoute,
    private http: HttpClient,
    private toaster: ToasterService,
  ) {}

  ngOnInit(): void {
    const idParam = this.route.snapshot.queryParamMap.get('userId');
    this.userId = idParam ? Number(idParam) : null;

    if (!this.userId) {
      this.toaster.error('Error', 'No user specified. Please log in first.');
      this.router.navigate(['']);
    }
  }

  verifyUser() {
    if (!this.userId) return;
    const url = `${environment.apiUrl}/Verification`;
    this.http.post<{ token: string }>(url, { token: this.token, userId: this.userId })
      .subscribe({
        next: (response) => {
          window.sessionStorage.setItem('my-auth-token', response.token);
          this.toaster.success('Verified!', 'Your account has been verified.');
          this.router.navigate(['home-page']);
        },
        error: (err) => {
          const msg = typeof err.error === 'string' ? err.error : 'Verification failed. Please try again.';
          this.toaster.error('Verification Error', msg);
        },
      });
  }
}
