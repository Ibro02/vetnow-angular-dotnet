import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PetsSettingsComponent } from './pets-settings.component';

describe('PetsSettingsComponent', () => {
  let component: PetsSettingsComponent;
  let fixture: ComponentFixture<PetsSettingsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PetsSettingsComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(PetsSettingsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
