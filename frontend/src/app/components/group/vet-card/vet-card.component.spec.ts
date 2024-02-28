import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VetCardComponent } from './vet-card.component';

describe('VetCardComponent', () => {
  let component: VetCardComponent;
  let fixture: ComponentFixture<VetCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VetCardComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(VetCardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
