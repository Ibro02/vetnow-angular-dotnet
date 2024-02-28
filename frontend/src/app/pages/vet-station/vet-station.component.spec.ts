import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VetStationComponent } from './vet-station.component';

describe('VetStationComponent', () => {
  let component: VetStationComponent;
  let fixture: ComponentFixture<VetStationComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VetStationComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(VetStationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
