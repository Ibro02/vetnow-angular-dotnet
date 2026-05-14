import { Component, EventEmitter, Input, Output } from '@angular/core';
import { NgIf } from '@angular/common';
import { scaleIn } from '../../../animations/shared.animations';

@Component({
  selector: 'app-confirm-modal',
  standalone: true,
  imports: [NgIf],
  templateUrl: './confirm-modal.component.html',
  styleUrl: './confirm-modal.component.css',
  animations: [scaleIn],
})
export class ConfirmModalComponent {
  @Input() visible = false;
  @Input() title = 'Are you sure?';
  @Input() message = 'This action cannot be undone.';
  @Input() confirmText = 'Confirm';
  @Input() cancelText = 'Cancel';
  /** When true the confirm button is styled red (for delete/remove actions) */
  @Input() isDanger = true;

  @Output() onConfirm = new EventEmitter<void>();
  @Output() onCancel = new EventEmitter<void>();

  confirm(): void {
    this.onConfirm.emit();
  }

  cancel(): void {
    this.onCancel.emit();
  }

  onOverlayClick(event: MouseEvent): void {
    // Only close if the click is directly on the overlay, not the card
    if (event.target === event.currentTarget) {
      this.cancel();
    }
  }
}
