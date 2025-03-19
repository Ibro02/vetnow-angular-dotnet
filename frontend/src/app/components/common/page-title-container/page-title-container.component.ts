import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-page-title-container',
  standalone: true,
  imports: [],
  templateUrl: './page-title-container.component.html',
  styleUrl: './page-title-container.component.css'
})
export class PageTitleContainerComponent {
@Input() public title?:string;
@Input() public subtitle?:string;
}
