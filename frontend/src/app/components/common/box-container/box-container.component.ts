import { Component, OnInit,Input } from '@angular/core';

@Component({
  selector: 'app-box-container',
  standalone: true,
  imports: [],
  templateUrl: './box-container.component.html',
  styleUrl: './box-container.component.css'
})
export class BoxContainerComponent implements OnInit{
ngOnInit(): void {
}

@Input() title: string = "(No title!)";

}
