import { Component, EventEmitter, Input, Output, OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { NgIf, NgFor } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonComponent } from '../../common/button/button.component';
import { Config } from '../../../config';
import { MyAuthService } from '../../../services/MyAuth';
import axios from 'axios';
import { DragDropModule } from '@angular/cdk/drag-drop';

interface SpeciesOption {
  id: number;
  name: string;
}

interface BreedOption {
  id: number;
  name: string;
}

export interface PetFormData {
  id: number | null;
  name: string;
  animalSpeciesId: number | null;
  breedId: number | null;
  birthDate: string;
  picture: string | null; // base64 data URI or null
}

// Predefined paw colors for pets without photos
const PAW_COLORS = [
  '#6366f1', // indigo
  '#ec4899', // pink
  '#f59e0b', // amber
  '#10b981', // emerald
  '#8b5cf6', // violet
  '#ef4444', // red
  '#06b6d4', // cyan
  '#f97316', // orange
  '#84cc16', // lime
  '#14b8a6', // teal
];

@Component({
  selector: 'app-pet-add-card',
  standalone: true,
  imports: [NgIf, NgFor, FormsModule, ButtonComponent, DragDropModule],
  templateUrl: './pet-add-card.component.html',
  styleUrl: './pet-add-card.component.css'
})
export class PetAddCardComponent implements OnInit, OnChanges {
  @Input() visible: boolean = false;
  @Input() editPetData: PetFormData | null = null;

  @Output() onSave = new EventEmitter<PetFormData>();
  @Output() onCancel = new EventEmitter<void>();

  // Form fields
  petName: string = '';
  selectedSpeciesId: number | null = null;
  selectedBreedId: number | null = null;
  birthDate: string = '';
  pictureBase64: string | null = null;
  petId: number | null = null;

  // Dropdown data
  speciesList: SpeciesOption[] = [];
  breedList: BreedOption[] = [];

  // Default paw color (for pets without photos)
  pawColor: string = '#9ca3af';

  isEditMode: boolean = false;

  constructor(private authService: MyAuthService) {}

  ngOnInit(): void {
    this.fetchSpecies();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['visible'] && this.visible) {
      this.fetchSpecies();

      if (this.editPetData) {
        this.isEditMode = true;
        this.petId = this.editPetData.id;
        this.petName = this.editPetData.name || '';
        this.selectedSpeciesId = this.editPetData.animalSpeciesId;
        this.birthDate = this.editPetData.birthDate || '';
        this.pictureBase64 = this.editPetData.picture;

        // Assign a consistent paw color based on pet ID
        if (this.petId) {
          this.pawColor = PAW_COLORS[this.petId % PAW_COLORS.length];
        }

        // Load breeds for the selected species, then set the breed
        if (this.selectedSpeciesId) {
          this.fetchBreeds(this.selectedSpeciesId).then(() => {
            this.selectedBreedId = this.editPetData!.breedId;
          });
        }
      } else {
        this.isEditMode = false;
        this.resetForm();
        // Random paw color for new pets
        this.pawColor = PAW_COLORS[Math.floor(Math.random() * PAW_COLORS.length)];
      }
    }
  }

  onDragOver(event: DragEvent) {
    event.preventDefault();
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
  }

  onFileDrop(event: DragEvent) {
    event.preventDefault();

    const file = event.dataTransfer?.files?.[0];
    if (!file) return;

    if (file.size > 2097152) {
      window.alert('File is too big! Maximum size is 2MB.');
      return;
    }

    const reader = new FileReader();
    reader.readAsDataURL(file);

    reader.onload = () => {
      this.pictureBase64 = reader.result as string;
    };
  }


  async fetchSpecies(): Promise<void> {
    try {
      const { data } = await axios.get<any[]>(
        Config.address + 'api/SpeciesGetAll/Get',
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );
      this.speciesList = data.map(s => ({
        id: s.id,
        name: s.speciesName || s.SpeciesName || ''
      }));
    } catch (error) {
      console.error('Failed to fetch species:', error);
    }
  }

  async fetchBreeds(speciesId: number): Promise<void> {
    try {
      const { data } = await axios.get<any[]>(
        Config.address + 'api/BreedGetBySpecies/Get?speciesId=' + speciesId,
        { headers: { 'my-auth-token': this.authService.token ?? '' } }
      );
      this.breedList = data.map(b => ({
        id: b.id,
        name: b.name || b.Name || ''
      }));
    } catch (error) {
      console.error('Failed to fetch breeds:', error);
      this.breedList = [];
    }
  }

  onSpeciesChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.selectedSpeciesId = value ? Number(value) : null;
    this.selectedBreedId = null;
    this.breedList = [];

    if (this.selectedSpeciesId) {
      this.fetchBreeds(this.selectedSpeciesId);
    }
  }

  onBreedChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.selectedBreedId = value ? Number(value) : null;
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    if (file.size > 2097152) {
      window.alert('File is too big! Maximum size is 2MB.');
      return;
    }

    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      this.pictureBase64 = reader.result as string;
    };
  }

  triggerFileInput(): void {
    const fileInput = document.getElementById('pet-photo-input') as HTMLInputElement;
    if (fileInput) {
      fileInput.click();
    }
  }

  removePhoto(): void {
    this.pictureBase64 = null;
  }

  save(): void {
    if (!this.petName.trim()) {
      window.alert('Please enter a pet name.');
      return;
    }

    const formData: PetFormData = {
      id: this.petId,
      name: this.petName.trim(),
      animalSpeciesId: this.selectedSpeciesId,
      breedId: this.selectedBreedId,
      birthDate: this.birthDate,
      picture: this.pictureBase64,
    };
    this.onSave.emit(formData);
  }

  cancel(): void {
    this.onCancel.emit();
  }

  resetForm(): void {
    this.petId = null;
    this.petName = '';
    this.selectedSpeciesId = null;
    this.selectedBreedId = null;
    this.birthDate = '';
    this.pictureBase64 = null;
    this.breedList = [];
  }
}
