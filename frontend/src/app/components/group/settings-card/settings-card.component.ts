import { NgFor, NgIf } from '@angular/common';
import { Component, Input } from '@angular/core';
import { SettingsCardContent } from '../../../services/interfaces/SettingsCard';
import { RouterLink } from '@angular/router';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';

@Component({
  selector: 'app-settings-card',
  standalone: true,
  imports: [NgFor, NgIf, RouterLink, FaIconComponent],
  templateUrl: './settings-card.component.html',
  styleUrl: './settings-card.component.css'
})
export class SettingsCardComponent {
  @Input() array?: SettingsCardContent[];
}
