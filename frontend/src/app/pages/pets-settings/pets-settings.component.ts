import { Component, OnInit } from '@angular/core';
import { NgFor, NgIf, DatePipe } from '@angular/common';
import { PetCardComponent } from '../../components/group/pet-card/pet-card.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { TableComponent, TableColumn } from '../../components/common/table/table.component';
import { ProfileService } from '../../services/ProfileService';
import { MyAuthService } from '../../services/MyAuth';
import { Config } from '../../config';
import axios from 'axios';

interface PetResponse {
  id: number;
  name: string;
  ownerId: number;
  birthDate: string;
  animalSpeciesId: number | null;
  speciesName: string | null;
  diet: string | null;
  breedId: number | null;
  breedName: string | null;
  picture: string | null;
  medicalFile: string | null;
  isFavourite: boolean | null;
}

@Component({
  selector: 'app-pets-settings',
  standalone: true,
  imports: [
    NgFor,
    NgIf,
    PetCardComponent,
    HeaderTitleComponent,
    TableComponent,
  ],
  templateUrl: './pets-settings.component.html',
  styleUrl: './pets-settings.component.css'
})
export class PetsSettingsComponent implements OnInit {
  pets: PetResponse[] = [];
  viewMode: 'card' | 'table' = 'card';

  tableColumns: TableColumn[] = [
    {
      key: 'name',
      label: 'Name',
      type: 'avatar',
      imageKey: 'pictureUrl',
    },
    {
      key: 'speciesName',
      label: 'Animal',
      type: 'text',
    },
    {
      key: 'breedName',
      label: 'Breed',
      type: 'text',
    },
    {
      key: 'diet',
      label: 'Diet',
      type: 'badge',
      badgeColorMap: {
        'Herbivore': 'badge-green',
        'Herbs': 'badge-green',
        'Carnivore': 'badge-red',
        'Omnivore': 'badge-default',
      },
    },
    {
      key: 'birthDateFormatted',
      label: 'Birth Date',
      type: 'text',
    },
  ];

  constructor(
    private profileService: ProfileService,
    private authService: MyAuthService,
  ) {}

  async ngOnInit(): Promise<void> {
    await this.profileService.getUserContent();
    await this.fetchPets();
  }

  async fetchPets(): Promise<void> {
    try {
      const url = 'api/PetsGetById/Get';
      const { data } = await axios.get<PetResponse[]>(
        Config.address + url,
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );
      this.pets = data;
    } catch (error) {
      console.error('Failed to fetch pets:', error);
    }
  }

  toggleViewMode(): void {
    this.viewMode = this.viewMode === 'card' ? 'table' : 'card';
  }

  get tableData(): any[] {
    return this.pets.map(pet => ({
      ...pet,
      pictureUrl: pet.picture ? 'data:image/png;base64,' + pet.picture : null,
      birthDateFormatted: this.formatDate(pet.birthDate),
    }));
  }

  getPetPictureUrl(pet: PetResponse): string | null {
    if (!pet.picture) return null;
    return 'data:image/png;base64,' + pet.picture;
  }

  calculateAge(birthDate: string): number {
    const birth = new Date(birthDate);
    const now = new Date();
    let age = now.getFullYear() - birth.getFullYear();
    const monthDiff = now.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '—';
    const date = new Date(dateStr);
    const day = date.getDate();
    const month = date.getMonth() + 1;
    const year = date.getFullYear();
    return `${day}.${month}.${year}`;
  }

  onTableAction(event: { action: string; row: any }): void {
    if (event.action === 'delete') {
      this.deletePet(event.row.id);
    } else if (event.action === 'edit') {
      this.editPet(event.row.id);
    }
  }

  deletePet(petId: number): void {
    console.log('Delete pet:', petId);
  }

  editPet(petId: number): void {
    console.log('Edit pet:', petId);
  }

  downloadPdf(petId: number): void {
    console.log('Download PDF:', petId);
  }

  addPet(): void {
    console.log('Add pet clicked');
  }
}
