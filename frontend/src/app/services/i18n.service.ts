import { Injectable } from '@angular/core';

// ─── Supported languages ───────────────────────────────────────────────────────

export type Lang = 'en' | 'bs';

// ─── Translation dictionary ────────────────────────────────────────────────────

export const TRANSLATIONS: Record<Lang, Record<string, string>> = {
  en: {
    // Page header
    pageTitle:       'My Profile',
    pageDescription: 'Edit your profile settings',

    // Form field labels
    firstName:   'First Name',
    lastName:    'Last Name',
    phone:       'Phone Number',
    address:     'Address',
    city:        'City',
    country:     'Country',
    email:       'Email',
    username:    'Username',
    password:    'Password',

    // Placeholders
    firstNamePlaceholder: 'Enter your first name',
    lastNamePlaceholder:  'Enter your last name',
    phonePlaceholder:     'Enter phone number',
    addressPlaceholder:   'Enter your address',
    cityPlaceholder:      'Enter city',
    countryPlaceholder:   'Enter country',
    emailPlaceholder:     'Enter email',
    usernamePlaceholder:  'Enter username',
    passwordPlaceholder:  'Enter password',

    // Sections
    profileImage:  'Profile Image',
    pickLocation:  'Pick location on map',

    // Crop wizard
    cropImage: 'Crop image',

    // Buttons
    cancel: 'Cancel',
    save:   'Save',

    // Language toggle tooltip
    switchLang: 'Switch to Bosnian',
  },

  bs: {
    // Zaglavlje stranice
    pageTitle:       'Moj profil',
    pageDescription: 'Uredite postavke vašeg profila',

    // Oznake polja forme
    firstName:   'Ime',
    lastName:    'Prezime',
    phone:       'Broj telefona',
    address:     'Adresa',
    city:        'Grad',
    country:     'Država',
    email:       'Email',
    username:    'Korisničko ime',
    password:    'Lozinka',

    // Placeholder tekst
    firstNamePlaceholder: 'Unesite vaše ime',
    lastNamePlaceholder:  'Unesite vaše prezime',
    phonePlaceholder:     'Unesite broj telefona',
    addressPlaceholder:   'Unesite adresu',
    cityPlaceholder:      'Unesite grad',
    countryPlaceholder:   'Unesite državu',
    emailPlaceholder:     'Unesite email',
    usernamePlaceholder:  'Unesite korisničko ime',
    passwordPlaceholder:  'Unesite lozinku',

    // Sekcije
    profileImage:  'Profilna slika',
    pickLocation:  'Odaberite lokaciju na mapi',

    // Čarobnjak za izrezivanje
    cropImage: 'Izreži sliku',

    // Dugmad
    cancel: 'Otkaži',
    save:   'Spremi',

    // Tooltip za prebacivanje jezika
    switchLang: 'Prebaci na engleski',
  },
};

// ─── Service ───────────────────────────────────────────────────────────────────

@Injectable({ providedIn: 'root' })
export class I18nService {
  currentLang: Lang = 'en';

  /** Translate a key for the current language. Falls back to the key itself. */
  t(key: string): string {
    return TRANSLATIONS[this.currentLang][key] ?? key;
  }

  /** Toggle between English and Bosnian. */
  toggle(): void {
    this.currentLang = this.currentLang === 'en' ? 'bs' : 'en';
  }
}
