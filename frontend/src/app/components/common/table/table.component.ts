import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';
import { NgFor, NgIf, NgClass } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface TableColumn {
  key: string;
  key2?: string;         // for avatar: concatenate with key (e.g. lastName)
  label: string;
  type: 'text' | 'avatar' | 'badge' | 'date';
  subtitleKey?: string;  // for avatar: secondary line (e.g. email)
  imageKey?: string;     // for avatar: image URL field
  badgeColorMap?: Record<string, string>; // value -> css class
}

@Component({
  selector: 'app-table',
  standalone: true,
  imports: [NgFor, NgIf, NgClass, FormsModule],
  templateUrl: './table.component.html',
  styleUrl: './table.component.css',
})
export class TableComponent {
  @Input() title: string = 'Table';
  @Input() columns: TableColumn[] = [];
  @Input() data: any[] = [];
  @Input() showSearch: boolean = true;
  @Input() showExportCsv: boolean = true;
  @Input() addButtonText?: string;
  @Input() rowColorKey?: string;
  @Input() rowColorMap?: Record<string, string>;

  @Output() addClick = new EventEmitter<void>();
  @Output() actionClick = new EventEmitter<{ action: string; row: any }>();

  searchQuery: string = '';
  searchVisible: boolean = false;
  openMenuIndex: number | null = null;

  get filteredData(): any[] {
    if (!this.searchQuery.trim()) return this.data;
    const q = this.searchQuery.toLowerCase();
    return this.data.filter(row =>
      this.columns.some(col => this.getCellValue(row, col).toLowerCase().includes(q))
    );
  }

  getCellValue(row: any, col: TableColumn): string {
    const v1 = row[col.key] ?? '';
    if (col.key2) return `${v1} ${row[col.key2] ?? ''}`.trim();
    return String(v1);
  }

  getInitials(row: any, col: TableColumn): string {
    return this.getCellValue(row, col)
      .split(' ')
      .map(n => n[0] ?? '')
      .join('')
      .toUpperCase()
      .slice(0, 2);
  }

  getBadgeClass(col: TableColumn, value: string): string {
    if (!col.badgeColorMap) return 'badge-default';
    return col.badgeColorMap[value] ?? 'badge-default';
  }

  getRowClass(row: any): string {
    if (!this.rowColorKey || !this.rowColorMap) return '';
    return this.rowColorMap[row[this.rowColorKey]] ?? '';
  }

  toggleSearch(): void {
    this.searchVisible = !this.searchVisible;
    if (!this.searchVisible) this.searchQuery = '';
  }

  toggleMenu(index: number, event: Event): void {
    event.stopPropagation();
    this.openMenuIndex = this.openMenuIndex === index ? null : index;
  }

  @HostListener('document:click')
  closeMenu(): void {
    this.openMenuIndex = null;
  }

  onAction(action: string, row: any): void {
    this.actionClick.emit({ action, row });
    this.openMenuIndex = null;
  }

  exportToCSV(): void {
    if (!this.data.length) return;
    const headers = this.columns.map(c => c.label).join(',');
    const rows = this.data.map(row =>
      this.columns.map(col => `"${this.getCellValue(row, col)}"`).join(',')
    );
    const csv = [headers, ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `${this.title.toLowerCase().replace(/\s+/g, '-')}.csv`;
    link.click();
  }
}
