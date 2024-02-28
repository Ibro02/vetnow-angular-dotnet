import { Component, Input, OnInit } from '@angular/core';

@Component({
  selector: 'app-about-us-footer',
  standalone: true,
  imports: [],
  templateUrl: './about-us-footer.component.html',
  styleUrl: './about-us-footer.component.css'
})
export class AboutUsFooterComponent implements OnInit{

  @Input() vetStationInfo:any;  //@todo - first finnish backend, then make changes in html

  ngOnInit(): void {
    
  }

email = 'vstanicazalik@gmail.com'
}
