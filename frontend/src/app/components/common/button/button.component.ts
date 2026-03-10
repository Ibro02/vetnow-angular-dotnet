import { Component, Input, Output, EventEmitter } from '@angular/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-button',
  standalone: true,
  imports: [NgClass],
  template: `
    <button
      [ngClass]="buttonClasses"
      [disabled]="disabled"
      (click)="handleEvent()">
      <ng-content></ng-content>
      {{ text }}
    </button>
  `,
  styleUrls: ['./button.component.css'],
})
export class ButtonComponent {
  @Output() event = new EventEmitter<void>();
  @Input() text = '';
  @Input() type: 'primary' | 'secondary' | 'tertiary' | 'danger' | 'ghost' | 'brand' = 'primary';
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() disabled = false;
  @Input() extraClass = '';

  get buttonClasses(): string {
    const variant = this.type === 'tertiary' ? 'secondary' : this.type;
    return `btn-${variant} ${this.size !== 'md' ? 'btn-' + this.size : ''} ${this.extraClass}`.trim();
  }

  handleEvent(): void {
    this.event.emit();
  }
}
