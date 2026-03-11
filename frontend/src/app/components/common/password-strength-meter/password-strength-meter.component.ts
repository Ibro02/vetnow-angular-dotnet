import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { NgClass } from '@angular/common';

export interface StrengthLevel {
  label: string;
  class: string;   // CSS modifier class
  segments: number; // how many of the 4 bar segments to fill
}

@Component({
  selector: 'app-password-strength-meter',
  standalone: true,
  imports: [NgClass],
  templateUrl: './password-strength-meter.component.html',
  styleUrl: './password-strength-meter.component.css',
})
export class PasswordStrengthMeterComponent implements OnChanges {
  @Input() password = '';

  strength: StrengthLevel = { label: '', class: '', segments: 0 };
  checks = {
    length: false,
    lowercase: false,
    uppercase: false,
    digit: false,
    special: false,
  };

  /** Segments array used by the template to render bars */
  segments = [1, 2, 3, 4];

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['password']) {
      this.evaluate(this.password);
    }
  }

  private evaluate(pw: string): void {
    this.checks = {
      length: pw.length >= 8,
      lowercase: /[a-z]/.test(pw),
      uppercase: /[A-Z]/.test(pw),
      digit: /\d/.test(pw),
      special: /[^a-zA-Z0-9]/.test(pw),
    };

    const passed = Object.values(this.checks).filter(Boolean).length;

    if (pw.length === 0) {
      this.strength = { label: '', class: '', segments: 0 };
    } else if (passed <= 2) {
      this.strength = { label: 'Weak', class: 'weak', segments: 1 };
    } else if (passed === 3) {
      this.strength = { label: 'Fair', class: 'fair', segments: 2 };
    } else if (passed === 4) {
      this.strength = { label: 'Good', class: 'good', segments: 3 };
    } else {
      this.strength = { label: 'Strong', class: 'strong', segments: 4 };
    }
  }
}
