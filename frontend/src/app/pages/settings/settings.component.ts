import {Component, OnInit} from '@angular/core';
import { SettingsCardComponent } from '../../components/group/settings-card/settings-card.component';
import { SettingsCardContent } from '../../services/interfaces/SettingsCard';
import { PageTitleContainerComponent } from "../../components/common/page-title-container/page-title-container.component";
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";
import {Router, RouterLink} from "@angular/router";
import { ToasterService} from "../../services/toaster.service";

@Component({
    selector: 'app-settings',
    standalone: true,
    templateUrl: './settings.component.html',
    styleUrl: './settings.component.css',
  imports: [SettingsCardComponent, PageTitleContainerComponent, HeaderTitleComponent, RouterLink]
})
export class SettingsComponent implements OnInit{
  constructor(
    private router:Router,
    private toaster: ToasterService,
  ) {
  }
  ngOnInit(): void {
    const hasVisited = localStorage.getItem('settingsVisited');

    if (!hasVisited) {
      this.showToast();
      localStorage.setItem('settingsVisited', 'true');
    }
  }

  showToast() {
    console.log("Prvi put u settingsu!");
    this.toaster.info('Short Cut', 'To access settings page use: ALT + S');
    // this.toastr.info("Ovdje možeš podesiti aplikaciju.");
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
