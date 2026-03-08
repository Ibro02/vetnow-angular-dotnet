import {Component, EventEmitter, Input, Output} from '@angular/core';
import {NgIf} from "@angular/common";
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faTrash, faFilePdf, faPenToSquare, faPaw, faRotateLeft} from "@fortawesome/free-solid-svg-icons";

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

  @Output() onDelete = new EventEmitter<number>();
  @Output() onRestore = new EventEmitter<number>();
  @Output() onDownloadPdf = new EventEmitter<number>();
  @Output() onEdit = new EventEmitter<number>();

  faPaw = faPaw;
  faTrash = faTrash;
  faRotateLeft = faRotateLeft;
  faFilePdf = faFilePdf;
  faPenToSquare = faPenToSquare;

  delete(): void {
    this.onDelete.emit(this.petId);
  }

  restore(): void {
    this.onRestore.emit(this.petId);
  }

  downloadPdf(): void {
    this.onDownloadPdf.emit(this.petId);
  }

  edit(): void {
    this.onEdit.emit(this.petId);
  }
}
