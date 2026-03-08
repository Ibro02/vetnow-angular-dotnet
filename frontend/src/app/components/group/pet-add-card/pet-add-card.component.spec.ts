import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PetAddCardComponent } from './pet-add-card.component';

describe('PetAddCardComponent', () => {
  let component: PetAddCardComponent;
  let fixture: ComponentFixture<PetAddCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PetAddCardComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(PetAddCardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
