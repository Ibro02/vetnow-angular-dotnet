import { Component, EventEmitter, Input, Output, OnChanges, SimpleChanges } from '@angular/core';
import { NgIf, NgFor, NgSwitch, NgSwitchCase } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonComponent } from '../../common/button/button.component';
import { DragDropModule } from '@angular/cdk/drag-drop';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';
import { faPaw } from '@fortawesome/free-solid-svg-icons';

// ─── Public Interfaces ────────────────────────────────────────────────────────

export interface FormFieldOption {
  id: any;
  name: string;
}

export interface FormFieldConfig {
  key: string;
  label: string;
  type: 'text' | 'number' | 'date' | 'dropdown' | 'textarea';
  required?: boolean;
  placeholder?: string;
  /** Maximum selectable date for date fields (ISO string YYYY-MM-DD) */
  maxDate?: string;
  /** Minimum selectable date for date fields (ISO string YYYY-MM-DD) */
  minDate?: string;
  /** Static options (used when loadOptions is absent) */
  options?: FormFieldOption[];
  /** Key of the parent dropdown this field depends on */
  dependsOn?: string;
  /** Async loader: called with no args for independent dropdowns,
   *  with the parent value for dependent dropdowns */
  loadOptions?: (parentValue?: any) => Promise<FormFieldOption[]>;
}

export interface DynamicFormConfig {
  title: string;
  editTitle: string;
  fields: FormFieldConfig[];
  /** Show the circular photo uploader on the right */
  showPhoto?: boolean;
  /** Key inside formValues where the base-64 photo string is stored */
  photoKey?: string;
}

// ─── Paw colours (fallback avatar for pets without photos) ────────────────────

const PAW_COLORS = [
  '#6366f1', '#ec4899', '#f59e0b', '#10b981', '#8b5cf6',
  '#ef4444', '#06b6d4', '#f97316', '#84cc16', '#14b8a6',
];

// ─── Component ────────────────────────────────────────────────────────────────

@Component({
  selector: 'app-dynamic-form-card',
  standalone: true,
  imports: [NgIf, NgFor, NgSwitch, NgSwitchCase, FormsModule, ButtonComponent, DragDropModule, FaIconComponent],
  templateUrl: './pet-add-card.component.html',
  styleUrl: './pet-add-card.component.css'
})
export class DynamicFormCardComponent implements OnChanges {
  @Input() visible: boolean = false;
  @Input() config!: DynamicFormConfig;
  /** null  → add mode,  object → edit mode */
  @Input() editData: Record<string, any> | null = null;

  @Output() onSave   = new EventEmitter<Record<string, any>>();
  @Output() onCancel = new EventEmitter<void>();

  /** All current form values keyed by field.key */
  formValues: Record<string, any> = {};
  /** Runtime dropdown option lists keyed by field.key */
  fieldOptions: Record<string, FormFieldOption[]> = {};

  isEditMode: boolean = false;
  pawColor: string = '#9ca3af';
  readonly faPaw = faPaw;

  // ── Photo helpers ──────────────────────────────────────────────────────────

  get photoValue(): string | null {
    if (!this.config?.showPhoto || !this.config?.photoKey) return null;
    return this.formValues[this.config.photoKey] ?? null;
  }

  set photoValue(val: string | null) {
    if (this.config?.showPhoto && this.config?.photoKey) {
      this.formValues[this.config.photoKey] = val;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['visible'] && this.visible) {
      this.isEditMode = !!this.editData;
      this.resetForm();

      if (this.isEditMode && this.editData) {
        // Populate formValues from editData
        for (const field of (this.config?.fields ?? [])) {
          if (this.editData[field.key] !== undefined) {
            this.formValues[field.key] = this.editData[field.key];
          }
        }
        // Copy photo value
        if (this.config?.showPhoto && this.config?.photoKey) {
          this.formValues[this.config.photoKey] = this.editData[this.config.photoKey] ?? null;
        }
        // Consistent paw colour based on entity id
        const id = this.editData['id'];
        this.pawColor = id != null
          ? PAW_COLORS[id % PAW_COLORS.length]
          : PAW_COLORS[Math.floor(Math.random() * PAW_COLORS.length)];
      } else {
        this.pawColor = PAW_COLORS[Math.floor(Math.random() * PAW_COLORS.length)];
      }

      // Load all independent dropdown options; then (in edit mode) dependent ones
      this.loadIndependentDropdowns();
    }
  }

  private resetForm(): void {
    this.formValues   = {};
    this.fieldOptions = {};
  }

  // ── Option loading ─────────────────────────────────────────────────────────

  private async loadIndependentDropdowns(): Promise<void> {
    if (!this.config) return;

    const independentFields = this.config.fields.filter(
      f => f.type === 'dropdown' && f.loadOptions && !f.dependsOn
    );

    await Promise.all(
      independentFields.map(async f => {
        try {
          this.fieldOptions[f.key] = await f.loadOptions!();
        } catch (e) {
          console.error(`Failed to load options for "${f.key}"`, e);
          this.fieldOptions[f.key] = [];
        }
      })
    );

    // In edit mode, load dependent dropdown options using the pre-filled parent values
    if (this.isEditMode && this.editData) {
      await this.loadDependentDropdownsForEdit();
    }
  }

  private async loadDependentDropdownsForEdit(): Promise<void> {
    if (!this.config || !this.editData) return;

    const dependentFields = this.config.fields.filter(
      f => f.type === 'dropdown' && f.dependsOn && f.loadOptions
    );

    for (const field of dependentFields) {
      const parentValue = this.formValues[field.dependsOn!] ?? this.editData[field.dependsOn!];
      if (parentValue != null) {
        try {
          this.fieldOptions[field.key] = await field.loadOptions!(parentValue);
        } catch (e) {
          console.error(`Failed to load dependent options for "${field.key}"`, e);
          this.fieldOptions[field.key] = [];
        }
      }
    }
  }

  // ── Template helpers ───────────────────────────────────────────────────────

  getOptions(field: FormFieldConfig): FormFieldOption[] {
    return this.fieldOptions[field.key] ?? field.options ?? [];
  }

  isDropdownDisabled(field: FormFieldConfig): boolean {
    if (!field.dependsOn) return false;
    const parentValue = this.formValues[field.dependsOn];
    return parentValue == null || parentValue === '';
  }

  // ── Dropdown change (handles cascading) ────────────────────────────────────

  async onDropdownChange(field: FormFieldConfig, value: any): Promise<void> {
    this.formValues[field.key] = value ?? null;

    if (!this.config) return;

    // Find all fields that depend on this one and reload them
    const dependentFields = this.config.fields.filter(f => f.dependsOn === field.key);
    for (const depField of dependentFields) {
      this.formValues[depField.key] = null;
      this.fieldOptions[depField.key] = [];

      if (value != null && depField.loadOptions) {
        try {
          this.fieldOptions[depField.key] = await depField.loadOptions(value);
        } catch (e) {
          console.error(`Failed to reload options for "${depField.key}"`, e);
        }
      }
    }
  }

  // ── Photo upload ───────────────────────────────────────────────────────────

  onDragOver(event: DragEvent): void  { event.preventDefault(); }
  onDragLeave(event: DragEvent): void { event.preventDefault(); }

  onFileDrop(event: DragEvent): void {
    event.preventDefault();
    const file = event.dataTransfer?.files?.[0];
    if (!file) return;
    this.readFile(file);
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.readFile(file);
  }

  private readFile(file: File): void {
    if (file.size > 2097152) {
      window.alert('File is too big! Maximum size is 2 MB.');
      return;
    }
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => { this.photoValue = reader.result as string; };
  }

  triggerFileInput(): void {
    const input = document.getElementById('dynamic-form-photo-input') as HTMLInputElement;
    if (input) input.click();
  }

  removePhoto(): void { this.photoValue = null; }

  // ── Save / Cancel ──────────────────────────────────────────────────────────

  save(): void {
    if (!this.config) return;

    for (const field of this.config.fields) {
      if (field.required) {
        const val = this.formValues[field.key];
        if (val == null || (typeof val === 'string' && !val.trim())) {
          window.alert(`Please fill in the required field: ${field.label}`);
          return;
        }
      }
      if (field.type === 'date' && this.formValues[field.key]) {
        const selected = new Date(this.formValues[field.key]);
        if (field.maxDate && selected > new Date(field.maxDate)) {
          window.alert(`${field.label} cannot be in the future.`);
          return;
        }
        if (field.minDate && selected < new Date(field.minDate)) {
          window.alert(`${field.label} is too far in the past.`);
          return;
        }
      }
    }

    this.onSave.emit({ ...this.formValues });
  }

  cancel(): void { this.onCancel.emit(); }
}
