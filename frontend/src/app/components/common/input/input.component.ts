import {Component, EventEmitter, Input, Output} from '@angular/core';
import {NgFor, NgIf, NgSwitch, NgSwitchCase, NgSwitchDefault} from '@angular/common';
import {FormControl, FormsModule, ReactiveFormsModule} from '@angular/forms';

@Component({
  selector: 'app-input',
  standalone: true,
  imports: [NgIf,FormsModule,ReactiveFormsModule,NgFor,NgSwitch,NgSwitchCase,NgSwitchDefault],
  templateUrl: './input.component.html',
  styleUrl: "./input.component.css",

})
export class InputComponent {
  @Output() public itemEvent = new EventEmitter<string>();
  @Input() public type:string = 'text';
  @Input() public label: string = 'Input';
  @Input() public placeholder?: string = "";
  @Input() public id: string = 'inputField';
  @Input() public name: string = 'inputField';
  @Input() public array: any = [1,2,3,4,5];
  @Input() public value?: string|boolean;
  @Input() formControl = new FormControl<string|boolean|null>(false); //add file type


  // @Input() public value:any;
test() {
  console.log(this.formControl.value)
}
  /**
   *
   */
  constructor() {
    if (typeof this.formControl.value === 'boolean') {
      this.formControl.setValue(false);
    } else {
      this.formControl.setValue('');
    }
  }
  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      if (file.size > 2097152) { //2MB
        window.alert("File is too big!");
      } else {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        this.value = reader.result as string;
        this.itemEvent.emit(this.value);
      }
      }
    }
  }
//  getValue = (_value:string) =>
//   {
// this.value = _value;
// this.itemEvent.emit(this.value);

// //console.log(_value);
//   } //another method for state management


}
