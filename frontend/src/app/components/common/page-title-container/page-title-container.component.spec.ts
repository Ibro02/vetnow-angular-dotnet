import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PageTitleContainerComponent } from './page-title-container.component';

describe('PageTitleContainerComponent', () => {
  let component: PageTitleContainerComponent;
  let fixture: ComponentFixture<PageTitleContainerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PageTitleContainerComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(PageTitleContainerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
