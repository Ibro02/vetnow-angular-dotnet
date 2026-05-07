import {AfterViewInit, Component, ElementRef, HostListener, OnInit, ViewChild} from '@angular/core';
import {BoxContainerComponent} from "../../components/common/box-container/box-container.component";
import {ButtonComponent} from "../../components/common/button/button.component";
import {ToasterService} from "../../services/toaster.service";
import {HeaderTitleComponent} from "../../components/common/header-title/header-title.component";
import {InputComponent} from "../../components/common/input/input.component";
import {FormBuilder, FormControl, FormGroup, ReactiveFormsModule, Validators} from "@angular/forms";
import {InputButtonComponent} from "../../components/common/input-button/input-button.component";
import {PageTitleContainerComponent} from "../../components/common/page-title-container/page-title-container.component";
import {TitleComponent} from "../../components/common/title/title.component";
import {VetCardComponent} from "../../components/group/vet-card/vet-card.component";
import {SettingsCardComponent} from "../../components/group/settings-card/settings-card.component";
import axios, {AxiosResponse} from "axios";
import {NgIf} from "@angular/common";
import {FaIconComponent} from "@fortawesome/angular-fontawesome";
import {faUser} from "@fortawesome/free-solid-svg-icons";
import * as L from 'leaflet';
import {MyAuthService} from "../../services/MyAuth";
import {Config} from "../../config";
import {Router} from "@angular/router";
import {I18nService} from "../../services/i18n.service";

@Component({
  selector: 'app-profile-settings',
  standalone: true,
  imports: [
    BoxContainerComponent,
    ButtonComponent,
    HeaderTitleComponent,
    ReactiveFormsModule,
    InputComponent,
    NgIf,
    FaIconComponent,
  ],
  templateUrl: './profile-settings.component.html',
  styleUrl: './profile-settings.component.css'
})
export class ProfileSettingsComponent implements OnInit, AfterViewInit {
  faUser = faUser;
  previewUrl: string | null = null;

  @ViewChild('mapContainer', { static: false }) mapContainer!: ElementRef;
  @ViewChild('cropImage') cropImageRef!: ElementRef<HTMLImageElement>;
  @ViewChild('cropArea') cropAreaRef!: ElementRef<HTMLDivElement>;
  map!: L.Map;
  marker!: L.Marker;

  // Crop wizard state
  showCropWizard = false;
  cropImageSrc: string | null = null;
  cropZoom = 1;
  cropOffsetX = 0;
  cropOffsetY = 0;
  private isPanning = false;
  private panStartX = 0;
  private panStartY = 0;
  private panInitialOffsetX = 0;
  private panInitialOffsetY = 0;

  constructor(
    private myAuthService: MyAuthService,
    private toaster: ToasterService,
    private router: Router,
    public i18n: I18nService,
  ) {}

  readonly passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,128}$/;

  profileSettingsFormGroup = new FormGroup({
    firstName: new FormControl("", [
      Validators.required,
      Validators.maxLength(50),
      Validators.pattern(/^[a-zA-Z\u00C0-\u024F\s'\-]+$/),
    ]),
    lastName: new FormControl("", [
      Validators.required,
      Validators.maxLength(50),
      Validators.pattern(/^[a-zA-Z\u00C0-\u024F\s'\-]+$/),
    ]),
    phone: new FormControl("", [
      Validators.required,
      Validators.pattern(/^\+?[\d\s\-()\.\+]{7,15}$/),
    ]),
    email: new FormControl("", [
      Validators.required,
      Validators.email,
      Validators.maxLength(254),
    ]),
    username: new FormControl("", [
      Validators.required,
      Validators.minLength(5),
      Validators.maxLength(30),
      Validators.pattern(/^[a-zA-Z0-9_\-]+$/),
    ]),
    password: new FormControl(""),   // optional — only validated if non-empty
    picture: new FormControl(""),    // optional — user may not change it
    city: new FormControl("", [Validators.maxLength(100)]),
    address: new FormControl("", [Validators.maxLength(200)]),
    country: new FormControl("", [Validators.maxLength(100)]),
  })


  ngOnInit(): void {
    this.fetchProfileInfo();
  }

  ngAfterViewInit(): void {
    this.initMap();
  }

  initMap(): void {
    const defaultLat = 43.8563;
    const defaultLng = 18.4131;

    // Fix Leaflet default icon paths (broken by Angular bundling)
    const iconDefault = L.icon({
      iconRetinaUrl: 'assets/marker-icon-2x.png',
      iconUrl: 'assets/marker-icon.png',
      shadowUrl: 'assets/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      tooltipAnchor: [16, -28],
      shadowSize: [41, 41]
    });
    L.Marker.prototype.options.icon = iconDefault;
    // Initialize Leaflet map
    this.map = L.map(this.mapContainer.nativeElement, {
      center: [defaultLat, defaultLng],
      zoom: 12,
    });

    // OpenStreetMap tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map);

    // Draggable marker
    this.marker = L.marker([defaultLat, defaultLng], { draggable: true }).addTo(this.map);

    // Click on map -> move marker & reverse geocode
    this.map.on('click', (event: L.LeafletMouseEvent) => {
      const { lat, lng } = event.latlng;
      this.marker.setLatLng([lat, lng]);
      this.reverseGeocode(lat, lng);
    });

    // Drag marker -> reverse geocode
    this.marker.on('dragend', () => {
      const position = this.marker.getLatLng();
      this.reverseGeocode(position.lat, position.lng);
    });
  }

  reverseGeocode(lat: number, lng: number): void {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`;

    fetch(url, {
      headers: { 'Accept-Language': 'en' }
    })
      .then(response => response.json())
      .then(data => {
        if (data && data.address) {
          const city = data.address.city || data.address.town || data.address.village || data.address.municipality || '';
          const country = data.address.country || '';

          this.profileSettingsFormGroup.controls.city.setValue(city);
          this.profileSettingsFormGroup.controls.country.setValue(country);
        }
      })
      .catch(err => {
        // reverse geocoding failed
      });
  }

  async fetchProfileInfo() {
    const token = this.myAuthService.token;
    if (!token) return;

    try {
      const response = await axios.get(
        Config.address + 'api/ProfileSettings/Get',
        { headers: { 'my-auth-token': token } }
      );
      const data = response.data;

      this.profileSettingsFormGroup.patchValue({
        firstName: data.firstName || '',
        lastName: data.lastName || '',
        phone: data.phone || '',
        email: data.email || '',
        username: data.username || '',
        city: data.city || '',
        country: data.country || '',
        address: data.address || '',
      });

      if (data.picture) {
        this.previewUrl = data.picture;
        this.profileSettingsFormGroup.controls.picture.setValue(data.picture);
      }
    } catch (err) {
      // failed to fetch profile info
    }
  }




  async saveChanges() {
    if (this.profileSettingsFormGroup.invalid) {
      this.toaster.error('Validation Error', 'Please correct the form errors before saving.');
      return;
    }
    const password = this.profileSettingsFormGroup.value.password;
    if (password && !this.passwordRegex.test(password)) {
      this.toaster.error('Validation Error', 'Password must be 8–128 characters with uppercase, lowercase, digit, and special character.');
      return;
    }
    const token = this.myAuthService.token;
    const apiUrl = Config.address + 'api/ProfileSettings/Edit';
    await axios
      .put(apiUrl, this.profileSettingsFormGroup.value, {
        headers: { 'my-auth-token': token }
      })
      .then((response: AxiosResponse<any>) => {
        this.toaster.success('Success!', 'Your operation completed successfully.');
      })
      .catch((err) => {
        this.toaster.error('Error occurred.', err);
      });
  }

  receiveImageURL(event: string) {
    this.profileSettingsFormGroup.value.picture = event;
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        const base64 = reader.result as string;
        this.cropImageSrc = base64;
        this.cropZoom = 1;
        this.cropOffsetX = 0;
        this.cropOffsetY = 0;
        this.showCropWizard = true;

        // Center the image after it loads
        setTimeout(() => this.centerImage(), 50);
      };
    }
    // Reset the input so re-selecting the same file triggers change
    event.target.value = '';
  }

  // --- Crop Wizard Methods ---

  openCropWizard(): void {
    // Trigger file input
    const fileInput = document.getElementById('fileInput') as HTMLInputElement;
    fileInput?.click();
  }

  closeCropWizard(): void {
    this.showCropWizard = false;
    this.cropImageSrc = null;
  }

  centerImage(): void {
    if (!this.cropImageRef || !this.cropAreaRef) return;
    const img = this.cropImageRef.nativeElement;
    const area = this.cropAreaRef.nativeElement;

    // Wait for natural dimensions
    if (img.naturalWidth === 0) {
      img.onload = () => this.centerImage();
      return;
    }

    // Scale image to fit the crop area
    const areaW = area.clientWidth;
    const areaH = area.clientHeight;
    const scale = Math.max(areaW / img.naturalWidth, areaH / img.naturalHeight);

    img.style.width = (img.naturalWidth * scale) + 'px';
    img.style.height = (img.naturalHeight * scale) + 'px';

    this.cropOffsetX = (areaW - img.naturalWidth * scale) / 2;
    this.cropOffsetY = (areaH - img.naturalHeight * scale) / 2;
    this.cropZoom = 1;
  }

  onZoomSlider(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.cropZoom = parseFloat(input.value);
  }

  onZoomWheel(event: WheelEvent): void {
    event.preventDefault();
    const delta = event.deltaY > 0 ? -0.05 : 0.05;
    this.cropZoom = Math.min(3, Math.max(0.5, this.cropZoom + delta));
  }

  onPanStart(event: MouseEvent): void {
    event.preventDefault();
    this.isPanning = true;
    this.panStartX = event.clientX;
    this.panStartY = event.clientY;
    this.panInitialOffsetX = this.cropOffsetX;
    this.panInitialOffsetY = this.cropOffsetY;
  }

  @HostListener('document:mousemove', ['$event'])
  onPanMove(event: MouseEvent): void {
    if (!this.isPanning) return;
    this.cropOffsetX = this.panInitialOffsetX + (event.clientX - this.panStartX);
    this.cropOffsetY = this.panInitialOffsetY + (event.clientY - this.panStartY);
  }

  @HostListener('document:mouseup')
  onPanEnd(): void {
    this.isPanning = false;
  }

  saveCroppedImage(): void {
    if (!this.cropImageRef || !this.cropAreaRef) return;

    const img = this.cropImageRef.nativeElement;
    const area = this.cropAreaRef.nativeElement;
    const areaW = area.clientWidth;
    const areaH = area.clientHeight;

    // The displayed image size (before CSS scale)
    const displayW = img.clientWidth;
    const displayH = img.clientHeight;

    // Circle radius matches CSS: 42% of the smaller dimension
    const circleRadius = Math.min(areaW, areaH) * 0.42;
    const circleCenterX = areaW / 2;
    const circleCenterY = areaH / 2;

    // CSS transform "translate(offsetX, offsetY) scale(zoom)" with transform-origin "center center"
    // means the image center stays at (offsetX + displayW/2, offsetY + displayH/2),
    // then scale is applied around the image's own center.
    //
    // The actual pixel position of the image's center on screen:
    const imgCenterScreenX = this.cropOffsetX + displayW / 2;
    const imgCenterScreenY = this.cropOffsetY + displayH / 2;

    // After scale, pixel at screen position P maps to image-display-space:
    // imgDisplayX = (P.x - imgCenterScreenX) / zoom + displayW/2
    //
    // We need to find what part of the displayed image falls inside the circle.
    // The circle center in image-display-space:
    const circleInImgX = (circleCenterX - imgCenterScreenX) / this.cropZoom + displayW / 2;
    const circleInImgY = (circleCenterY - imgCenterScreenY) / this.cropZoom + displayH / 2;

    // Radius in image-display-space:
    const radiusInImg = circleRadius / this.cropZoom;

    // Scale factor from display pixels to natural image pixels
    const natScaleX = img.naturalWidth / displayW;
    const natScaleY = img.naturalHeight / displayH;

    // Source rectangle in natural image coordinates
    const srcX = (circleInImgX - radiusInImg) * natScaleX;
    const srcY = (circleInImgY - radiusInImg) * natScaleY;
    const srcSize = radiusInImg * 2 * natScaleX; // assuming uniform scale

    // Output canvas
    const outputSize = 400; // fixed output resolution
    const canvas = document.createElement('canvas');
    canvas.width = outputSize;
    canvas.height = outputSize;
    const ctx = canvas.getContext('2d')!;

    // Clip to circle
    ctx.beginPath();
    ctx.arc(outputSize / 2, outputSize / 2, outputSize / 2, 0, Math.PI * 2);
    ctx.closePath();
    ctx.clip();

    // Draw the source region into the full canvas
    ctx.drawImage(
      img,
      srcX, srcY, srcSize, srcSize,  // source rect from natural image
      0, 0, outputSize, outputSize     // destination: full canvas
    );

    // Export as base64
    const croppedBase64 = canvas.toDataURL('image/png');
    this.previewUrl = croppedBase64;
    this.profileSettingsFormGroup.controls.picture.setValue(croppedBase64);
    this.showCropWizard = false;
    this.cropImageSrc = null;
  }

  navigateToSettings(){
    this.router.navigate(['settings']);
  }

}
