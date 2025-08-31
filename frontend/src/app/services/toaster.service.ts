// toaster.service.ts
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface ToastMessage {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message?: string;
  duration?: number;
  dismissible?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ToasterService {
  private toastsSubject = new BehaviorSubject<ToastMessage[]>([]);
  public toasts$ = this.toastsSubject.asObservable();

  private generateId(): string {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
  }

  private addToast(toast: Omit<ToastMessage, 'id'>): void {
    const newToast: ToastMessage = {
      id: this.generateId(),
      dismissible: true,
      duration: 5000,
      ...toast
    };

    const currentToasts = this.toastsSubject.value;
    this.toastsSubject.next([...currentToasts, newToast]);

    if (newToast.duration && newToast.duration > 0) {
      setTimeout(() => {
        this.remove(newToast.id);
      }, newToast.duration);
    }
  }

  success(title: string, message?: string, options?: Partial<ToastMessage>): void {
    this.addToast({
      type: 'success',
      title,
      message,
      ...options
    });
  }

  error(title: string, message?: string, options?: Partial<ToastMessage>): void {
    this.addToast({
      type: 'error',
      title,
      message,
      duration: 0, // Error messages don't auto-dismiss by default
      ...options
    });
  }

  warning(title: string, message?: string, options?: Partial<ToastMessage>): void {
    this.addToast({
      type: 'warning',
      title,
      message,
      duration: 8000,
      ...options
    });
  }

  info(title: string, message?: string, options?: Partial<ToastMessage>): void {
    this.addToast({
      type: 'info',
      title,
      message,
      ...options
    });
  }

  remove(id: string): void {
    const currentToasts = this.toastsSubject.value;
    this.toastsSubject.next(currentToasts.filter(toast => toast.id !== id));
  }

  clear(): void {
    this.toastsSubject.next([]);
  }
}
