import { NgFor, NgIf } from '@angular/common';
import { Component, Input } from '@angular/core';
import { SettingsCardContent } from '../../../services/interfaces/SettingsCard';

@Component({
  selector: 'app-settings-card',
  standalone: true,
  imports: [NgFor,NgIf],
  templateUrl: './settings-card.component.html',
  styleUrl: './settings-card.component.css'
})
export class SettingsCardComponent {
@Input() array?:SettingsCardContent[];

}
