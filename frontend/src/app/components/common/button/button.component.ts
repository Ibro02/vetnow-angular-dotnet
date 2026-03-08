import { Component, Input, OnInit, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-button',
  standalone: true,
  imports: [],
  templateUrl: './button.component.html',
  styleUrls: ['./button.component.css'],
})
export class ButtonComponent implements OnInit {
  @Output() event = new EventEmitter<void>();
  @Input() text: string = 'Button';
  @Input() type?: keyof IButtonType;

  color: string = 'bg-emerald-400';
  textColor: string = 'text-white';

  ngOnInit(): void {
    switch (this.type) {
      case 'primary':
        this.color = 'bg-emerald-400';
        break;
      case 'secondary':
        this.color = 'bg-neutral-600';
        break;
      case 'tertiary':
        this.color = 'bg-neutral-100';
        this.textColor = 'text-secondary';
        break;
      default:
        this.color = 'bg-emerald-400';
        break;
    }
  }

  handleEvent(): void {
    this.event.emit();
  }
}

export interface IButtonType {
  [key: string]: 'primary' | 'secondary' | 'tertiary' // Extend as needed
}
