import {Component, EventEmitter, Input, Output} from '@angular/core';
import {FormsModule} from "@angular/forms";
import {NgIf, NgSwitch, NgSwitchCase} from "@angular/common";
@Component({
  selector: 'app-sign-in-input',
  standalone: true,
  imports: [
    FormsModule,
    NgSwitch,
    NgSwitchCase,
    NgIf
  ],
  templateUrl: './sign-in-input.component.html',
  styleUrl: './sign-in-input.component.css'
})
export class SignInInputComponent {
  @Input() inputValue:string = "";
  @Output() valueChanged:EventEmitter<string> = new EventEmitter<string>();
  @Input() inputType:string = "text";
  @Input() title:string|null = null;
  @Input() isError = false;
  @Input() isSettings = false;
  @Input() size?:number;

  errorColor = 'text-red-600'; //tailwind property
  margin = 'mt-10';
  onInputChange() {
    this.valueChanged.emit(this.inputValue);
  }


}
