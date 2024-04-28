import { Component, Input } from '@angular/core';
import { NgIf, NgSwitch, NgSwitchCase, NgSwitchDefault } from '@angular/common';
@Component({
  selector: 'app-input',
  standalone: true,
  imports: [NgIf,NgSwitch,NgSwitchCase,NgSwitchDefault],
  templateUrl: './input.component.html',
  styleUrl: './input.component.css'
})
export class InputComponent {
  @Input() public type:string = 'text';
  @Input() public label: string = 'Input';
  @Input() public placeholder?: string = "";
  @Input() public id: string = 'inputField';
  @Input() public name: string = 'inputField';
}
