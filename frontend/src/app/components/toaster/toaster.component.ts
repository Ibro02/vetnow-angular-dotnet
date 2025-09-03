// toaster.component.ts
import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, takeUntil } from 'rxjs';
import { ToasterService, ToastMessage } from '../../services/toaster.service';
import { trigger, state, style, transition, animate } from '@angular/animations';

@Component({
  selector: 'app-toaster',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="toast-container">
      <div
        *ngFor="let toast of toasts; trackBy: trackByToastId"
        class="toast toast-{{toast.type}}"
        [@slideIn]
        [attr.role]="toast.type === 'error' ? 'alert' : 'status'"
        [attr.aria-live]="toast.type === 'error' ? 'assertive' : 'polite'"
      >
        <div class="toast-icon">
          <svg *ngIf="toast.type === 'success'" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/>
          </svg>
          <svg *ngIf="toast.type === 'error'" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
          </svg>
          <svg *ngIf="toast.type === 'warning'" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
          </svg>
          <svg *ngIf="toast.type === 'info'" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
          </svg>
        </div>

        <div class="toast-content">
          <div class="toast-title">{{ toast.title }}</div>
          <div *ngIf="toast.message" class="toast-message">{{ toast.message }}</div>
        </div>

        <button
          *ngIf="toast.dismissible"
          class="toast-close"
          (click)="removeToast(toast.id)"
          aria-label="Close notification"
          type="button"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
          </svg>
        </button>
      </div>
    </div>
  `,
  styles: [`
    .toast-container {
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 12px;
      max-width: 400px;
      width: 100%;
      pointer-events: none;
    }

    .toast {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 16px;
      border-radius: 12px;
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.05);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255, 255, 255, 0.2);
      pointer-events: auto;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
      overflow: hidden;
    }

    .toast:hover {
      transform: translateY(-2px);
      box-shadow: 0 20px 35px rgba(0, 0, 0, 0.15), 0 8px 12px rgba(0, 0, 0, 0.1);
    }

    .toast::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 3px;
      background: currentColor;
    }

    .toast-success {
      background: linear-gradient(135deg, rgba(16, 185, 129, 0.95) 0%, rgba(5, 150, 105, 0.95) 100%);
      color: white;
      border-color: rgba(16, 185, 129, 0.3);
    }

    .toast-error {
      background: linear-gradient(135deg, rgba(239, 68, 68, 0.95) 0%, rgba(220, 38, 38, 0.95) 100%);
      color: white;
      border-color: rgba(239, 68, 68, 0.3);
    }

    .toast-warning {
      background: linear-gradient(135deg, rgba(245, 158, 11, 0.95) 0%, rgba(217, 119, 6, 0.95) 100%);
      color: white;
      border-color: rgba(245, 158, 11, 0.3);
    }

    .toast-info {
      background: linear-gradient(135deg, rgba(59, 130, 246, 0.95) 0%, rgba(37, 99, 235, 0.95) 100%);
      color: white;
      border-color: rgba(59, 130, 246, 0.3);
    }

    .toast-icon {
      flex-shrink: 0;
      width: 20px;
      height: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-top: 2px;
      opacity: 0.9;
    }

    .toast-content {
      flex: 1;
      min-width: 0;
    }

    .toast-title {
      font-weight: 600;
      font-size: 14px;
      line-height: 1.4;
      margin-bottom: 2px;
    }

    .toast-message {
      font-weight: 400;
      font-size: 13px;
      line-height: 1.4;
      opacity: 0.9;
    }

    .toast-close {
      flex-shrink: 0;
      background: none;
      border: none;
      color: inherit;
      cursor: pointer;
      padding: 4px;
      border-radius: 6px;
      transition: all 0.2s ease;
      opacity: 0.7;
      margin-top: -2px;
      margin-right: -4px;
    }

    .toast-close:hover {
      opacity: 1;
      background: rgba(255, 255, 255, 0.1);
      transform: scale(1.1);
    }

    .toast-close:active {
      transform: scale(0.95);
    }

    .toast-close svg {
      display: block;
    }

    /* Mobile responsiveness */
    @media (max-width: 480px) {
      .toast-container {
        top: 10px;
        right: 10px;
        left: 10px;
        max-width: none;
      }

      .toast {
        padding: 14px;
        gap: 10px;
      }

      .toast-title {
        font-size: 13px;
      }

      .toast-message {
        font-size: 12px;
      }
    }

    /* Dark mode support */
    @media (prefers-color-scheme: dark) {
      .toast {
        border-color: rgba(255, 255, 255, 0.1);
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3), 0 4px 6px rgba(0, 0, 0, 0.1);
      }

      .toast:hover {
        box-shadow: 0 20px 35px rgba(0, 0, 0, 0.4), 0 8px 12px rgba(0, 0, 0, 0.2);
      }
    }
  `],
  animations: [
    trigger('slideIn', [
      transition(':enter', [
        style({
          transform: 'translateX(100%)',
          opacity: 0
        }),
        animate('300ms cubic-bezier(0.4, 0, 0.2, 1)', style({
          transform: 'translateX(0)',
          opacity: 1
        }))
      ]),
      transition(':leave', [
        animate('200ms cubic-bezier(0.4, 0, 0.2, 1)', style({
          transform: 'translateX(100%)',
          opacity: 0
        }))
      ])
    ])
  ]
})
export class ToasterComponent implements OnInit, OnDestroy {
  toasts: ToastMessage[] = [];
  private destroy$ = new Subject<void>();

  constructor(private toasterService: ToasterService) {}

  ngOnInit(): void {
    this.toasterService.toasts$
      .pipe(takeUntil(this.destroy$))
      .subscribe(toasts => {
        this.toasts = toasts;
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  removeToast(id: string): void {
    this.toasterService.remove(id);
  }

  trackByToastId(index: number, toast: ToastMessage): string {
    return toast.id;
  }
}

// Usage example in a component:
/*
import { Component } from '@angular/core';
import { ToasterService } from './toaster.service';

@Component({
  selector: 'app-example',
  template: `
    <div>
      <button (click)="showSuccess()">Success Toast</button>
      <button (click)="showError()">Error Toast</button>
      <button (click)="showWarning()">Warning Toast</button>
      <button (click)="showInfo()">Info Toast</button>
      <button (click)="clearAll()">Clear All</button>
    </div>
  `
})
export class ExampleComponent {
  constructor(private toaster: ToasterService) {}

  showSuccess() {
    this.toaster.success('Success!', 'Your operation completed successfully.');
  }

  showError() {
    this.toaster.error('Error occurred', 'Please try again later.');
  }

  showWarning() {
    this.toaster.warning('Warning', 'Please check your input.');
  }

  showInfo() {
    this.toaster.info('Information', 'Here is some useful information.');
  }

  clearAll() {
    this.toaster.clear();
  }
}
*/
