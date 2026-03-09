import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';
import { NgFor, NgIf, NgClass } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface TableAction {
  key: string;
  label: string;
  isDanger?: boolean;
}

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
  @Input() actions: TableAction[] = [
    { key: 'edit', label: 'Edit' },
    { key: 'delete', label: 'Delete', isDanger: true }
  ];

  // Pagination inputs
  @Input() showPagination: boolean = false;
  @Input() totalCount: number = 0;
  @Input() pageSize: number = 10;
  @Input() currentPage: number = 1;
  @Input() pageSizeOptions: number[] = [5, 10, 20];

  @Output() addClick = new EventEmitter<void>();
  @Output() actionClick = new EventEmitter<{ action: string; row: any }>();
  @Output() pageChange = new EventEmitter<{ pageNumber: number; pageSize: number }>();
  @Output() searchChange = new EventEmitter<string>();

  searchQuery: string = '';
  searchVisible: boolean = false;
  openMenuIndex: number | null = null;
  private searchTimer: any = null;

  get filteredData(): any[] {
    // When server-side pagination is active, don't filter client-side
    if (this.showPagination) return this.data;
    if (!this.searchQuery.trim()) return this.data;
    const q = this.searchQuery.toLowerCase();
    return this.data.filter(row =>
      this.columns.some(col => this.getCellValue(row, col).toLowerCase().includes(q))
    );
  }

  get totalPages(): number {
    if (!this.showPagination) return 1;
    return Math.ceil(this.totalCount / this.pageSize) || 1;
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
    if (!this.searchVisible) {
      this.searchQuery = '';
      this.searchChange.emit('');
    }
  }

  onSearchInput(): void {
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => {
      this.searchChange.emit(this.searchQuery);
    }, 400);
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

  // Pagination methods
  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages) return;
    this.currentPage = page;
    this.pageChange.emit({ pageNumber: this.currentPage, pageSize: this.pageSize });
  }

  onPageSizeChange(newSize: number): void {
    this.pageSize = newSize;
    this.currentPage = 1;
    this.pageChange.emit({ pageNumber: 1, pageSize: this.pageSize });
  }

  get paginationStart(): number {
    return (this.currentPage - 1) * this.pageSize + 1;
  }

  get paginationEnd(): number {
    return Math.min(this.currentPage * this.pageSize, this.totalCount);
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
