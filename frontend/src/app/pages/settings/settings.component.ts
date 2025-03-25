import { Component } from '@angular/core';
import { SettingsCardComponent } from '../../components/group/settings-card/settings-card.component';
import { SettingsCardContent } from '../../services/interfaces/SettingsCard';
import { PageTitleContainerComponent } from "../../components/common/page-title-container/page-title-container.component";
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";

@Component({
    selector: 'app-settings',
    standalone: true,
    templateUrl: './settings.component.html',
    styleUrl: './settings.component.css',
  imports: [SettingsCardComponent, PageTitleContainerComponent, HeaderTitleComponent]
})
export class SettingsComponent {
  public accountSettingsArr: SettingsCardContent[] = [
    { link: '/settings/my-profile', text: 'My profile' },
    { link: '/settings/my-pets', text: 'My pets' },
    { link: '/settings/appearance', text: 'Appearance' },
    { link: '/settings/subscriptions', text: 'Subscriptions' },
  ];

  public workspaceSettingsArr: SettingsCardContent[] = [
    { link: '/settings/vet-station', text: 'Workspace' },
    { link: '/settings/employees', text: 'Employees' },
    { link: '/settings/posts', text: 'Posts' },
  ];
}
