import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AppointmentLayoutComponent } from './appointment-layout.component';

describe('AppointmentLayoutComponent', () => {
  let component: AppointmentLayoutComponent;
  let fixture: ComponentFixture<AppointmentLayoutComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppointmentLayoutComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(AppointmentLayoutComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
