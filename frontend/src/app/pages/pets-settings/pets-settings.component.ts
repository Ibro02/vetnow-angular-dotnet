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
import { environment } from '../../../environment';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import {
  DynamicFormCardComponent,
  DynamicFormConfig,
} from '../../components/group/pet-add-card/pet-add-card.component';
import { ConfirmModalComponent } from '../../components/common/confirm-modal/confirm-modal.component';


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
    DynamicFormCardComponent,
    ConfirmModalComponent,
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

  // Confirm modal state
  showDeleteConfirm = false;
  showRestoreConfirm = false;
  confirmTargetPetId: number | null = null;
  confirmTargetPetName = '';

  // Pet add/edit popup state
  showPetForm: boolean = false;
  editingPetData: Record<string, any> | null = null;

  /** Config-driven form definition — built once in ngOnInit */
  petFormConfig?: DynamicFormConfig;

  constructor(
    private profileService: ProfileService,
    private authService: MyAuthService,
    private http: HttpClient,
  ) {}

  async ngOnInit(): Promise<void> {
    // Build the form config here so arrow-function lambdas can close over
    // `this.authService` which is fully initialised by this point.
    this.petFormConfig = {
      title:     'Add New Pet',
      editTitle: 'Edit Pet',
      showPhoto: true,
      photoKey:  'picture',
      fields: [
        {
          key:         'name',
          label:       'Name',
          type:        'text',
          required:    true,
          placeholder: 'Enter pet name',
        },
        {
          key:      'animalSpeciesId',
          label:    'Select species',
          type:     'dropdown',
          required: true,
          loadOptions: async () => {
            const res: any = await firstValueFrom(
              this.http.get(`${environment.apiUrl}/api/SpeciesGetAll/Get`)
            );
            return res.dataItems.map((s: any) => ({
              id:   s.id,
              name: s.speciesName || s.SpeciesName || '',
            }));
          },
        },
        {
          key:       'breedId',
          label:     'Select breed',
          type:      'dropdown',
          dependsOn: 'animalSpeciesId',
          loadOptions: async (speciesId: any) => {
            const data = await firstValueFrom(
              this.http.get<any[]>(
                `${environment.apiUrl}/api/BreedGetBySpecies/Get?speciesId=${speciesId}`
              )
            );
            return data.map((b: any) => ({
              id:   b.id,
              name: b.name || b.Name || '',
            }));
          },
        },
        {
          key:     'birthDate',
          label:   'Birth Date',
          type:    'date',
          maxDate: new Date().toISOString().split('T')[0],
        },
      ],
    };

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

      const data = await firstValueFrom(
        this.http.get<PagedResponse<PetResponse>>(
          `${environment.apiUrl}/${url}?${queryString}`
        )
      );

      this.pets = data.dataItems;
      this.totalCount = data.totalCount;
      this.currentPage = data.currentPage;
      this.pageSize = data.pageSize;
    } catch (error) {
      // failed to fetch pets
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
      this.requestDeletePet(event.row.id);
    } else if (event.action === 'edit') {
      this.editPet(event.row.id);
    }
  }

  /** Show delete confirmation modal */
  requestDeletePet(petId: number): void {
    const pet = this.pets.find(p => p.id === petId);
    this.confirmTargetPetId = petId;
    this.confirmTargetPetName = pet?.name ?? 'this pet';
    this.showDeleteConfirm = true;
  }

  /** Show restore confirmation modal */
  requestRestorePet(petId: number): void {
    const pet = this.pets.find(p => p.id === petId);
    this.confirmTargetPetId = petId;
    this.confirmTargetPetName = pet?.name ?? 'this pet';
    this.showRestoreConfirm = true;
  }

  /** Actually perform delete after user confirms */
  async confirmDeletePet(): Promise<void> {
    if (this.confirmTargetPetId == null) return;
    this.showDeleteConfirm = false;
    try {
      await firstValueFrom(
        this.http.delete(`${environment.apiUrl}/api/Pets/SoftDelete?id=${this.confirmTargetPetId}`, { responseType: 'text' })
      );
      await this.fetchPets(this.activeSearchQuery, this.currentPage, this.pageSize, this.statusFilter);
    } catch (error) {
      // failed to delete pet
    }
    this.confirmTargetPetId = null;
  }

  /** Actually perform restore after user confirms */
  async confirmRestorePet(): Promise<void> {
    if (this.confirmTargetPetId == null) return;
    this.showRestoreConfirm = false;
    try {
      await firstValueFrom(
        this.http.put(`${environment.apiUrl}/api/Pets/Restore?id=${this.confirmTargetPetId}`, {}, { responseType: 'text' })
      );
      await this.fetchPets(this.activeSearchQuery, this.currentPage, this.pageSize, this.statusFilter);
    } catch (error) {
      // failed to restore pet
    }
    this.confirmTargetPetId = null;
  }

  cancelConfirm(): void {
    this.showDeleteConfirm = false;
    this.showRestoreConfirm = false;
    this.confirmTargetPetId = null;
  }

  editPet(petId: number): void {
    const pet = this.pets.find(p => p.id === petId);
    if (!pet) return;

    // Format date for the date input (YYYY-MM-DD)
    let formattedDate = '';
    if (pet.birthDate) {
      const d = new Date(pet.birthDate);
      const year  = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day   = String(d.getDate()).padStart(2, '0');
      formattedDate = `${year}-${month}-${day}`;
    }

    // editingPetData is passed as [editData] to the dynamic form component.
    // The 'id' key is not a form field — the save handler reads it here to
    // construct the update request body.
    this.editingPetData = {
      id:             pet.id,
      name:           pet.name,
      animalSpeciesId: pet.animalSpeciesId,
      breedId:        pet.breedId,
      birthDate:      formattedDate,
      picture:        this.getPetPictureUrl(pet),
    };
    this.showPetForm = true;
  }

  downloadPdf(petId: number): void {
    // download PDF
  }

  addPet(): void {
    this.editingPetData = null;
    this.showPetForm = true;
  }

  /** Receives the generic Record emitted by DynamicFormCardComponent */
  async onPetSave(formData: Record<string, any>): Promise<void> {
    try {
      const requestBody: any = {
        name:           formData['name'],
        birthDate:      formData['birthDate'] || null,
        animalSpeciesId: formData['animalSpeciesId'],
        breedId:        formData['breedId'],
      };

      // In edit mode the id lives in editingPetData (not emitted by the form)
      if (this.editingPetData?.['id']) {
        requestBody.id = this.editingPetData['id'];
      }

      if (formData['picture']) {
        requestBody.picture = formData['picture'];
      }

      await firstValueFrom(
        this.http.post(`${environment.apiUrl}/api/PetsUpdateOrInsert/Save`, requestBody)
      );

      this.showPetForm = false;
      this.editingPetData = null;
      await this.fetchPets(this.activeSearchQuery, this.currentPage, this.pageSize, this.statusFilter);
    } catch (error) {
      // failed to save pet
    }
  }

  onPetCancel(): void {
    this.showPetForm = false;
    this.editingPetData = null;
  }

  async exportMedicalReport(): Promise<void> {
    const ownerId = this.pets.length > 0 ? this.pets[0].ownerId : null;

    if (!ownerId) {
      alert('No available pets to generate the pdf');
      return;
    }

    try {
      const url = `${environment.apiUrl}/api/PetsReport/Generate?OwnerId=${ownerId}`;

      const blob = await firstValueFrom(
        this.http.get(url, { responseType: 'blob' })
      );
      const downloadUrl = window.URL.createObjectURL(blob);

      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `Medicinski_Karton_Vlasnik_${ownerId}.pdf`;

      document.body.appendChild(link);
      link.click();

      document.body.removeChild(link);
      window.URL.revokeObjectURL(downloadUrl);

    } catch (error) {
      // failed to generate PDF
      alert('Failed while generating PDF');
    }
  }
}
