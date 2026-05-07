import {Component, OnInit} from '@angular/core';
import { SettingsCardComponent } from '../../components/group/settings-card/settings-card.component';
import { SettingsCardContent } from '../../services/interfaces/SettingsCard';
import { PageTitleContainerComponent } from "../../components/common/page-title-container/page-title-container.component";
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";
import {Router, RouterLink} from "@angular/router";
import { ToasterService} from "../../services/toaster.service";
import { MyAuthService } from "../../services/MyAuth";
import { NgIf } from '@angular/common';
import {
  faUser,
  faPaw,
  faPalette,
  faCreditCard,
  faBriefcase,
  faUsers,
  faNewspaper,
  faClock,
  faShieldHalved
} from '@fortawesome/free-solid-svg-icons';

@Component({
    selector: 'app-settings',
    standalone: true,
    templateUrl: './settings.component.html',
    styleUrl: './settings.component.css',
  imports: [SettingsCardComponent, PageTitleContainerComponent, HeaderTitleComponent, RouterLink, NgIf]
})
export class SettingsComponent implements OnInit{
  constructor(
    private router:Router,
    private toaster: ToasterService,
    public auth: MyAuthService,
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
    this.toaster.info('Short Cut', 'To access settings easily use: ALT + S');
  }


  public accountSettingsArr: SettingsCardContent[] = [
    { link: '/settings/profile-settings', text: 'My profile',    icon: faUser       },
    { link: '/settings/my-pets',          text: 'My pets',       icon: faPaw        },
    { link: '/settings/appearance',       text: 'Appearance',    icon: faPalette    },
    { link: '/settings/subscriptions',    text: 'Subscriptions', icon: faCreditCard },
  ];

  // MainVet+ only: manage the workspace and employee roster
  public workspaceSettingsArr: SettingsCardContent[] = [
    { link: '/settings/vet-station', text: 'Workspace', icon: faBriefcase },
    { link: '/settings/employees',   text: 'Employees', icon: faUsers     },
  ];

  // Employee+ sees: Posts and Availability
  public employeeExtrasArr: SettingsCardContent[] = [
    { link: '/settings/posts',        text: 'Posts',        icon: faNewspaper },
    { link: '/settings/availability', text: 'Availability', icon: faClock     },
  ];

  public adminSettingsArr: SettingsCardContent[] = [
    { link: '/admin-panel', text: 'Admin Panel', icon: faShieldHalved },
  ];

  OpenProfileSettings() {
    this.router.navigate(['settings/profile-settings']);
  }

}
