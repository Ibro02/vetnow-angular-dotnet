import { Component, OnInit,Input } from '@angular/core';
import {NgIf} from "@angular/common";

@Component({
  selector: 'app-box-container',
  standalone: true,
  imports: [
    NgIf
  ],
  templateUrl: './box-container.component.html',
  styleUrl: './box-container.component.css'
})
export class BoxContainerComponent implements OnInit{
ngOnInit(): void {
}

@Input() title?: string;

}
