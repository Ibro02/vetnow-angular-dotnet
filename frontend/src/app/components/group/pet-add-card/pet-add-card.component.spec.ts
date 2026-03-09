import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DynamicFormCardComponent } from './pet-add-card.component';

describe('DynamicFormCardComponent', () => {
  let component: DynamicFormCardComponent;
  let fixture: ComponentFixture<DynamicFormCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DynamicFormCardComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DynamicFormCardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
