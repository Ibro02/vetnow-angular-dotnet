import { NgFor, NgIf } from '@angular/common';
import { Component, Input } from '@angular/core';
import { SettingsCardContent } from '../../../services/interfaces/SettingsCard';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-settings-card',
  standalone: true,
  imports: [NgFor, NgIf, RouterLink],
  templateUrl: './settings-card.component.html',
  styleUrl: './settings-card.component.css'
})
export class SettingsCardComponent {
@Input() array?:SettingsCardContent[];

}
