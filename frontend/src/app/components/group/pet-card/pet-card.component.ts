import {Component, EventEmitter, Input, Output} from '@angular/core';
import {NgIf} from "@angular/common";
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faTrash, faFilePdf, faPenToSquare, faPaw, faRotateLeft} from "@fortawesome/free-solid-svg-icons";

const GRADIENTS = [
  'linear-gradient(135deg, #818cf8 0%, #6366f1 35%, #c084fc 70%, #e9d5ff 100%)', // indigo → purple
  'linear-gradient(135deg, #34d399 0%, #10b981 35%, #06b6d4 70%, #a7f3d0 100%)', // emerald → cyan
  'linear-gradient(135deg, #f472b6 0%, #ec4899 35%, #e879f9 70%, #fbcfe8 100%)', // pink → fuchsia
  'linear-gradient(135deg, #fb923c 0%, #f97316 35%, #fbbf24 70%, #fed7aa 100%)', // orange → amber
  'linear-gradient(135deg, #60a5fa 0%, #3b82f6 35%, #818cf8 70%, #bfdbfe 100%)', // blue → indigo
  'linear-gradient(135deg, #a78bfa 0%, #8b5cf6 35%, #ec4899 70%, #ede9fe 100%)', // violet → pink
  'linear-gradient(135deg, #2dd4bf 0%, #14b8a6 35%, #34d399 70%, #99f6e4 100%)', // teal → emerald
  'linear-gradient(135deg, #f87171 0%, #ef4444 35%, #fb923c 70%, #fecaca 100%)', // red → orange
];

@Component({
  selector: 'app-pet-card',
  standalone: true,
  imports: [NgIf, FaIconComponent],
  templateUrl: './pet-card.component.html',
  styleUrl: './pet-card.component.css'
})
export class PetCardComponent {

  @Input() name: string = '';
  @Input() species: string = '';
  @Input() breed: string = '';
  @Input() age: number = 0;
  @Input() picture: string | null = null;
  @Input() petId: number = 0;
  @Input() isDeleted: boolean = false;
  /** Position of this card in the list — drives the gradient colour cycle */
  @Input() cardIndex: number = 0;

  get gradientStyle(): string {
    return GRADIENTS[this.cardIndex % GRADIENTS.length];
  }

  @Output() onDelete = new EventEmitter<number>();
  @Output() onRestore = new EventEmitter<number>();
  @Output() onDownloadPdf = new EventEmitter<number>();
  @Output() onEdit = new EventEmitter<number>();

  faPaw = faPaw;
  faTrash = faTrash;
  faRotateLeft = faRotateLeft;
  faFilePdf = faFilePdf;
  faPenToSquare = faPenToSquare;

  delete(): void    { this.onDelete.emit(this.petId); }
  restore(): void   { this.onRestore.emit(this.petId); }
  downloadPdf(): void { this.onDownloadPdf.emit(this.petId); }
  edit(): void      { this.onEdit.emit(this.petId); }
}
