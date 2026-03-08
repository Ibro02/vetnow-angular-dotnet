import { Component } from '@angular/core';
import { SettingsCardComponent } from '../../components/group/settings-card/settings-card.component';
import { SettingsCardContent } from '../../services/interfaces/SettingsCard';
import { PageTitleContainerComponent } from "../../components/common/page-title-container/page-title-container.component";
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";
import {Router, RouterLink} from "@angular/router";

@Component({
    selector: 'app-settings',
    standalone: true,
    templateUrl: './settings.component.html',
    styleUrl: './settings.component.css',
  imports: [SettingsCardComponent, PageTitleContainerComponent, HeaderTitleComponent, RouterLink]
})
export class SettingsComponent {
  constructor(
    private router:Router,
  ) {
  }


  public accountSettingsArr: SettingsCardContent[] = [
    { link: '/settings/profile-settings', text: 'My profile' },
    { link: '/settings/my-pets', text: 'My pets' },
    { link: '/settings/appearance', text: 'Appearance' },
    { link: '/settings/subscriptions', text: 'Subscriptions' },
  ];

  public workspaceSettingsArr: SettingsCardContent[] = [
    { link: '/settings/vet-station', text: 'Workspace' },
    { link: '/settings/employees', text: 'Employees' },
    { link: '/settings/posts', text: 'Posts' },
  ];

  OpenProfileSettings() {
    this.router.navigate(['settings/profile-settings']);
  }

}
