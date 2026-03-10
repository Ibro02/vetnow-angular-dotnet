import {Component, EventEmitter, HostListener, Input, Output} from '@angular/core';
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faFilter} from "@fortawesome/free-solid-svg-icons";
import {FormsModule} from "@angular/forms";
import {InputButtonComponent} from "../input-button/input-button.component";
import {NgForOf, NgIf} from "@angular/common";
import {ElementRef} from "@angular/core";
import {VetStationService} from "../../../services/VetStationSearch";

@Component({
  selector: 'app-search-input',
  standalone: true,
  imports: [
    FaIconComponent,
    FormsModule,
    InputButtonComponent,
    NgForOf,
    NgIf
  ],
  templateUrl: './search-input.component.html',
  styleUrl: './search-input.component.css'
})
export class InputComponent {

  protected readonly faFilter = faFilter;

  filterIsClicked: boolean = false;
  @Output() handleChangeFilter = this.vetStationService.dropdown;

constructor(private elementRef:ElementRef, public vetStationService:VetStationService) {
}

@Output() searchVetStation:EventEmitter<any> = new EventEmitter<any>();
@Input() searchValue?: string
  @HostListener('document:click', ['$event'])
  clickOutside(event: Event) {
    const target = event.target as HTMLElement;

    if (!this.elementRef.nativeElement.contains(target)) {
      this.filterIsClicked = false;
    }
  }
  handleChange(temp: boolean, i: number, j: number) {
    temp = !temp;
    this.vetStationService.dropdown[i].children[j].value = temp;
    this.vetStationService.setValues();
  }

  get activeFilterCount(): number {
    return this.vetStationService.dropdown
      .reduce((acc: number, group: any) =>
        acc + group.children.filter((c: any) => c.value).length, 0);
  }
}
