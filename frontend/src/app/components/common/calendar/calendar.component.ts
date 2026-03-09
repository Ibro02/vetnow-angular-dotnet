import {Component, EventEmitter, Input, Output} from '@angular/core';
import {NgForOf, NgIf, NgClass} from "@angular/common";
import {ActivatedRoute, Route, Router, RouterLink} from "@angular/router";

@Component({
  selector: 'app-calendar',
  standalone: true,
  imports: [
    NgForOf,
    NgIf,
    NgClass,
    RouterLink
  ],
  templateUrl: './calendar.component.html',
  styleUrl: './calendar.component.css'
})
export class CalendarComponent {
  @Output() changeDate = new EventEmitter<Date>();
  @Input() highlightedDates: Date[] = [];
  currentDate: Date = new Date();
  selectedDate: Date | null = new Date();
  constructor(public router: Router, private route: ActivatedRoute) {
  }
  get month(): string {
    return this.currentDate.toLocaleString('default', { month: 'long' });
  }

  get year(): number {
    return this.currentDate.getFullYear();
  }

  get daysInMonth(): number {
    return new Date(this.year, this.currentDate.getMonth() + 1, 0).getDate();
  }

  get firstDayOfMonth(): number {
    return new Date(this.year, this.currentDate.getMonth(), 1).getDay();
  }

  previousMonth(): void {
    this.currentDate.setMonth(this.currentDate.getMonth() - 1);
    this.currentDate = new Date(this.currentDate);
  }

  nextMonth(): void {
    this.currentDate.setMonth(this.currentDate.getMonth() + 1);
    this.currentDate = new Date(this.currentDate);
  }

  selectDate(day: number): void {
    this.selectedDate = new Date(this.year, this.currentDate.getMonth(), day);
    this.changeDate.emit(new Date(this.year, this.currentDate.getMonth(), day + 1));

    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        date: new Date(this.year, this.currentDate.getMonth(), day + 1).toISOString(),
      },
      queryParamsHandling: 'merge',
    });

    //this.router.navigate([{date: this.selectedDate.toISOString()}]);
  }

  private today: Date = new Date();

  isToday(day: number): boolean {
    return this.today.getFullYear() === this.year
      && this.today.getMonth() === this.currentDate.getMonth()
      && this.today.getDate() === day;
  }

  isHighlighted(day: number): boolean {
    return this.highlightedDates.some(d => {
      const hd = new Date(d);
      // Use UTC to avoid timezone shifting the date forward by one day
      return hd.getUTCFullYear() === this.year
        && hd.getUTCMonth() === this.currentDate.getMonth()
        && hd.getUTCDate() === day;
    });
  }

  protected readonly Date = Date;
}
