import { Component, OnInit, OnDestroy } from '@angular/core';
import { NgFor, NgIf } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';
import { PetCardComponent } from '../../components/group/pet-card/pet-card.component';
import { HeaderTitleComponent } from '../../components/common/header-title/header-title.component';
import { TableComponent, TableColumn } from '../../components/common/table/table.component';
import { ProfileService } from '../../services/ProfileService';
import { MyAuthService } from '../../services/MyAuth';
import { Config } from '../../config';
import axios from 'axios';
import { PetAddCardComponent, PetFormData } from '../../components/group/pet-add-card/pet-add-card.component';



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
  isDeleted: boolean | null;
}

interface PagedResponse<T> {
  dataItems: T[];
  currentPage: number;
  totalPages: number;
  pageSize: number;
  totalCount: number;
  hasPrevious: boolean;
  hasNext: boolean;
}

@Component({
  selector: 'app-pets-settings',
  standalone: true,
  imports: [
    NgFor,
    NgIf,
    FormsModule,
    PetCardComponent,
    HeaderTitleComponent,
    TableComponent,
    PetAddCardComponent,

  ],
  templateUrl: './pets-settings.component.html',
  styleUrl: './pets-settings.component.css'
})
export class PetsSettingsComponent implements OnInit, OnDestroy {
  pets: PetResponse[] = [];
  viewMode: 'card' | 'table' = 'card';

  // Search
  searchQuery: string = '';
  private searchSubject = new Subject<string>();
  private searchSubscription!: Subscription;
  private activeSearchQuery: string = '';

  // Status filter — 'active' | 'deleted' | 'all'
  statusFilter: string = 'active';

  readonly statusOptions = [
    { value: 'active',  label: 'Active' },
    { value: 'deleted', label: 'Deleted' },
    { value: 'all',     label: 'All' },
  ];

  // Paging
  currentPage: number = 1;
  pageSize: number = 5;
  totalCount: number = 0;

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

  // Pet add/edit popup state
  showPetForm: boolean = false;
  editingPetData: PetFormData | null = null;

  constructor(
    private profileService: ProfileService,
    private authService: MyAuthService,
  ) {}

  async ngOnInit(): Promise<void> {
    this.initSearchListener();
    await this.profileService.getUserContent();
    await this.fetchPets();
  }

  ngOnDestroy(): void {
    this.searchSubscription?.unsubscribe();
  }

  initSearchListener(): void {
    this.searchSubscription = this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      map(q => q.toLowerCase()),
      map(q => q.length > 2 ? q : ''),
    ).subscribe((filterValue) => {
      this.activeSearchQuery = filterValue;
      this.currentPage = 1;
      this.fetchPets(filterValue, 1, this.pageSize, this.statusFilter);
    });
  }

  onSearchInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value.trim();
    this.searchSubject.next(value);
  }

  async fetchPets(
    filter: string = '',
    page: number = 1,
    pageSize: number = 5,
    statusFilter: string = this.statusFilter,
  ): Promise<void> {
    try {
      const url = 'api/PetsGetById/Get';
      const params: Record<string, string | number> = {
        pageNumber: page,
        pageSize: pageSize,
        statusFilter: statusFilter,
      };
      if (filter) {
        params['q'] = filter;
      }

      const queryString = Object.entries(params)
        .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
        .join('&');

      const { data } = await axios.get<PagedResponse<PetResponse>>(
        Config.address + url + '?' + queryString,
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );

      this.pets = data.dataItems;
      this.totalCount = data.totalCount;
      this.currentPage = data.currentPage;
      this.pageSize = data.pageSize;
    } catch (error) {
      console.error('Failed to fetch pets:', error);
    }
  }

  onStatusFilterChange(value: string): void {
    this.statusFilter = value;
    this.currentPage = 1;
    this.fetchPets(this.activeSearchQuery, 1, this.pageSize, value);
  }

  onPageChange(event: { pageNumber: number; pageSize: number }): void {
    this.currentPage = event.pageNumber;
    this.pageSize = event.pageSize;
    this.fetchPets(this.activeSearchQuery, event.pageNumber, event.pageSize);
  }

  get totalPages(): number {
    return Math.ceil(this.totalCount / this.pageSize);
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

  async deletePet(petId: number): Promise<void> {
    try {
      await axios.delete(
        Config.address + 'api/Pets/SoftDelete?id=' + petId,
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );
      await this.fetchPets(this.activeSearchQuery, this.currentPage, this.pageSize, this.statusFilter);
    } catch (error) {
      console.error('Failed to delete pet:', error);
    }
  }

  async restorePet(petId: number): Promise<void> {
    try {
      await axios.put(
        Config.address + 'api/Pets/Restore?id=' + petId,
        {},
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );
      await this.fetchPets(this.activeSearchQuery, this.currentPage, this.pageSize, this.statusFilter);
    } catch (error) {
      console.error('Failed to restore pet:', error);
    }
  }

  editPet(petId: number): void {
    const pet = this.pets.find(p => p.id === petId);
    if (!pet) return;

    // Format date for the date input (YYYY-MM-DD)
    let formattedDate = '';
    if (pet.birthDate) {
      const d = new Date(pet.birthDate);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      formattedDate = `${year}-${month}-${day}`;
    }

    this.editingPetData = {
      id: pet.id,
      name: pet.name,
      animalSpeciesId: pet.animalSpeciesId,
      breedId: pet.breedId,
      birthDate: formattedDate,
      picture: this.getPetPictureUrl(pet),
    };
    this.showPetForm = true;
  }

  downloadPdf(petId: number): void {
    console.log('Download PDF:', petId);
  }

  addPet(): void {
    this.editingPetData = null;
    this.showPetForm = true;
  }

  async onPetSave(formData: PetFormData): Promise<void> {
    try {
      const requestBody: any = {
        name: formData.name,
        birthDate: formData.birthDate || null,
        animalSpeciesId: formData.animalSpeciesId,
        breedId: formData.breedId,
      };

      if (formData.id) {
        requestBody.id = formData.id;
      }

      if (formData.picture) {
        requestBody.picture = formData.picture;
      }

      await axios.post(
        Config.address + 'api/PetsUpdateOrInsert/Save',
        requestBody,
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );

      this.showPetForm = false;
      this.editingPetData = null;
      await this.fetchPets(this.activeSearchQuery, this.currentPage, this.pageSize, this.statusFilter);
    } catch (error) {
      console.error('Failed to save pet:', error);
    }
  }

  onPetCancel(): void {
    this.showPetForm = false;
    this.editingPetData = null;
  }

  async exportMedicalReport(): Promise<void> {
    // Uzimamo OwnerId iz prvog učitanog ljubimca
    const ownerId = this.pets.length > 0 ? this.pets[0].ownerId : null;

    if (!ownerId) {
      alert('Nema dostupnih ljubimaca za generisanje izvještaja.');
      return;
    }

    try {
      // 1. URL sa samo jednim parametrom
      const url = `${Config.address}api/PetsReport/Generate?OwnerId=${ownerId}`;

      // 2. Axios poziv
      const response = await axios.get(url, {
        headers: { 'my-auth-token': this.authService.token ?? '' },
        responseType: 'blob' // Obavezno za fajlove
      });

      // 3. Hendlanje preuzetog fajla
      const blob = new Blob([response.data], { type: 'application/pdf' });
      const downloadUrl = window.URL.createObjectURL(blob);

      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `Medicinski_Karton_Vlasnik_${ownerId}.pdf`;

      document.body.appendChild(link);
      link.click();

      // 4. Čišćenje
      document.body.removeChild(link);
      window.URL.revokeObjectURL(downloadUrl);

    } catch (error) {
      console.error('Greška pri preuzimanju PDF-a:', error);
      alert('Došlo je do greške prilikom generisanja izvještaja.');
    }
  }
}
