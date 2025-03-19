import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BoxContainerComponent } from './box-container.component';

describe('BoxContainerComponent', () => {
  let component: BoxContainerComponent;
  let fixture: ComponentFixture<BoxContainerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BoxContainerComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(BoxContainerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
