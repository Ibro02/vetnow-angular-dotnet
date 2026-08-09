// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bosnian (`bs`).
class AppLocalizationsBs extends AppLocalizations {
  AppLocalizationsBs([String locale = 'bs']) : super(locale);

  @override
  String get appTitle => 'VetNow';

  @override
  String get navExplore => 'Istraži';

  @override
  String get navAppointments => 'Termini';

  @override
  String get navProfile => 'Profil';

  @override
  String get exploreHeroTitle => 'Pouzdana njega,\nrezervisana za sekunde.';

  @override
  String get exploreHeroSubtitle =>
      'Pregledaj provjerene klinike blizu tebe — bez računa za pregledanje.';

  @override
  String get searchHint => 'Pretraži klinike, usluge…';

  @override
  String get filterRecommended => 'Preporučeno';

  @override
  String get filterTopRated => 'Najbolje ocijenjeno';

  @override
  String get filterNearest => 'Najbliže';

  @override
  String get filterOpenNow => 'Otvoreno sada';

  @override
  String clinicsInCity(int count, String city) {
    return '$count klinika u $city';
  }

  @override
  String get noClinicsMatch => 'Nijedna klinika ne odgovara tvojim filterima';

  @override
  String get chooseCity => 'Odaberi grad';

  @override
  String get loginTitle => 'Prijava';

  @override
  String get loginBookingGateTitle => 'Skoro gotovo';

  @override
  String get loginBookingGateSubtitle =>
      'Prijavi se da potvrdiš termin — traje sekundu.';

  @override
  String get loginWelcomeSubtitle => 'Drago nam je da si opet tu! 🐾';

  @override
  String get usernameOrEmail => 'Korisničko ime / Email';

  @override
  String get password => 'Lozinka';

  @override
  String get keepSignedIn => 'Ostani prijavljen/a';

  @override
  String get forgotPassword => 'Zaboravljena lozinka?';

  @override
  String get signIn => 'Prijavi se';

  @override
  String get loginInvalidCredentials => 'Pogrešno korisničko ime ili lozinka.';

  @override
  String get loginNeedsVerification =>
      'Račun nije verifikovan. Poslali smo novi kod na tvoj email.';

  @override
  String get networkError =>
      'Nešto nije uspjelo. Provjeri internet konekciju i pokušaj ponovo.';

  @override
  String get retry => 'Pokušaj ponovo';

  @override
  String get registerSuccessCheckEmail =>
      'Račun je kreiran! Provjeri email da ga verifikuješ, pa se prijavi.';

  @override
  String get passwordRequirementsHint =>
      'Najmanje 8 znakova: veliko i malo slovo, broj i specijalni znak.';

  @override
  String get noAccount => 'Nemaš račun?';

  @override
  String get register => 'Registruj se';

  @override
  String get createAccount => 'Kreiraj račun';

  @override
  String get registerSubtitle =>
      'Kreiraj račun da rezervišeš termine i upravljaš ljubimcima.';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Prezime';

  @override
  String get email => 'Email';

  @override
  String get username => 'Korisničko ime';

  @override
  String get createAccountButton => 'Kreiraj račun';

  @override
  String get backToLogin => 'Nazad na prijavu';

  @override
  String get myAppointments => 'Moji termini';

  @override
  String get appointmentsSubtitle => 'Prati svoje buduće i prošle posjete';

  @override
  String get upcoming => 'Nadolazeći';

  @override
  String get pastVisits => 'Prošle posjete';

  @override
  String get statusCompleted => 'Završeno';

  @override
  String get statusCancelled => 'Otkazano';

  @override
  String get noUpcoming => 'Nema nadolazećih termina.';

  @override
  String get noPast => 'Još nema prošlih termina.';

  @override
  String get noAppointmentsYet => 'Još nema termina';

  @override
  String get profileTitle => 'Profil';

  @override
  String get guestTitle => 'Pregledaš kao gost';

  @override
  String get guestMessage =>
      'Kreiraj račun da sačuvaš svoje ljubimce, pratiš historiju posjeta i brže rezervišeš sljedeći put.';

  @override
  String get guestBenefit1 =>
      'Sačuvaj podatke o ljubimcima jednom, koristi za svaku rezervaciju';

  @override
  String get guestBenefit2 => 'Vodi evidenciju svake posjete i vakcinacije';

  @override
  String get guestBenefit3 => 'Preskoči ponovno unošenje podataka sljedeći put';

  @override
  String get logInRegister => 'Prijava / Registracija';

  @override
  String get takesLessThanMinute => 'Traje manje od minute.';

  @override
  String get myPets => 'Moji ljubimci';

  @override
  String get viewAll => 'Pogledaj sve';

  @override
  String get addPet => 'Dodaj ljubimca';

  @override
  String get account => 'Račun';

  @override
  String get personalInfo => 'Lični podaci';

  @override
  String get passwordSecurity => 'Lozinka i sigurnost';

  @override
  String get notifications => 'Obavještenja';

  @override
  String get helpSupport => 'Pomoć i podrška';

  @override
  String get logOut => 'Odjavi se';

  @override
  String get member => 'Član';

  @override
  String get memberSince => 'Član od';

  @override
  String get pets => 'Ljubimci';

  @override
  String get logOutConfirmTitle => 'Odjava?';

  @override
  String get logOutConfirmMessage =>
      'Uvijek se možeš ponovo prijaviti da vidiš svoje ljubimce i termine.';

  @override
  String get stayLoggedIn => 'Ostani prijavljen/a';

  @override
  String get cancelAppointmentTitle => 'Otkazati termin?';

  @override
  String get cancelAppointmentMessage =>
      'Ovo se ne može poništiti. Trebat ćeš rezervisati novi termin ako se predomisliš.';

  @override
  String get keepIt => 'Zadrži';

  @override
  String get cancelAppointmentAction => 'Otkaži termin';

  @override
  String get reschedule => 'Promijeni termin';

  @override
  String get bookAgain => 'Rezerviši ponovo';

  @override
  String get bookAppointment => 'Rezerviši termin';

  @override
  String get chooseService => 'Odaberi uslugu';

  @override
  String get chooseStaffOptional => 'Odaberi osoblje (opcionalno)';

  @override
  String get pickTimeToday => 'Odaberi vrijeme — danas';

  @override
  String get pickTimeAbove => 'Odaberi vrijeme iznad';

  @override
  String get choosePet => 'Odaberi ljubimca';

  @override
  String get noPetsYet => 'Nemaš dodanih ljubimaca.';

  @override
  String get addPetFirst => 'Dodaj ljubimca da nastaviš';

  @override
  String get noSlotsToday =>
      'Nema slobodnih termina danas kod ovog zaposlenika.';

  @override
  String get bookingFailed =>
      'Rezervacija nije uspjela — termin je možda upravo zauzet. Pokušaj ponovo.';

  @override
  String get signInToSeeRealAvailability =>
      'Prijavljen/a si — sad biraš iz stvarno dostupnog osoblja i termina.';

  @override
  String get anyAvailable => 'Bilo ko dostupan';

  @override
  String get confirmBooking => 'Potvrdi rezervaciju';

  @override
  String get selectServiceAndTime => 'Odaberi uslugu i vrijeme';

  @override
  String get bookingSummary => 'Pregled rezervacije';

  @override
  String todayAtDuration(String slot, int duration) {
    return 'Danas u $slot · $duration min';
  }

  @override
  String get total => 'Ukupno';

  @override
  String get youAreBooked => 'Rezervisano je!';

  @override
  String bookingConfirmedMessage(String clinicName) {
    return 'Tvoj termin u $clinicName je potvrđen. Poslali smo detalje na tvoj email.';
  }

  @override
  String get backToExplore => 'Nazad na Istraži';

  @override
  String get call => 'Pozovi';

  @override
  String get book => 'Rezerviši';

  @override
  String get verifiedPartner => 'Verifikovani partner';

  @override
  String get whatIsVerifiedPartner => 'Šta znači Verifikovani partner?';

  @override
  String get verifiedPartnerExplanation =>
      'Licenca ove klinike je provjerena u registru Veterinarske komore, a njeno osoblje i usluge prikazane ovdje pregledao je VetNow tim.';

  @override
  String get gotIt => 'Razumijem';

  @override
  String get ourTeam => 'Naš tim';

  @override
  String get meetTheTeam => 'Upoznaj tim';

  @override
  String get openHoursToday => 'Otvoreno sada · Pon–Sub, 08:00–18:00';

  @override
  String get closedOpensTomorrow => 'Zatvoreno sada · Otvara se pon u 08:00';

  @override
  String get sortByRating => 'Sortiraj po ocjeni';

  @override
  String get allServices => 'Sve usluge';

  @override
  String get reviews => 'Recenzije';

  @override
  String get openNow => 'Otvoreno sada';

  @override
  String get closedNow => 'Zatvoreno sada';

  @override
  String get language => 'Jezik';

  @override
  String get chooseLanguage => 'Odaberi jezik';

  @override
  String get bosnian => 'Bosanski';

  @override
  String get croatian => 'Hrvatski';

  @override
  String get serbian => 'Srpski';

  @override
  String get savePet => 'Sačuvaj ljubimca';

  @override
  String get tellUsAboutFriend => 'Reci nam o svom prijatelju';

  @override
  String get weightOptional => 'Težina (kg) — opcionalno';

  @override
  String get breed => 'Rasa';

  @override
  String get species => 'Vrsta';

  @override
  String get petName => 'Ime';

  @override
  String get petInfoNote =>
      'Vakcinacije i druge detalje možeš dodati kasnije sa profila ljubimca.';

  @override
  String get deletePet => 'Ukloni ljubimca';

  @override
  String deletePetConfirmTitle(String name) {
    return 'Ukloniti $name?';
  }

  @override
  String get deletePetConfirmMessage => 'Ovo se ne može poništiti.';

  @override
  String get deletePetAction => 'Ukloni';

  @override
  String get details => 'Detalji';

  @override
  String get vaccinationHistory => 'Historija vakcinacije';

  @override
  String get noVaccinationRecords =>
      'Još nema zapisa o vakcinaciji.\nTvoja veterinarska stanica ih može dodati poslije posjete.';

  @override
  String get weight => 'Težina';

  @override
  String get microchip => 'Mikročip';

  @override
  String get age => 'Starost';

  @override
  String get sectionAppointment => 'Termin';

  @override
  String get appointmentDetails => 'Detalji termina';

  @override
  String get sectionSpecialist => 'Specijalista';

  @override
  String get sectionClinic => 'Klinika';

  @override
  String get labelService => 'Usluga';

  @override
  String get labelDetails => 'Detalji';

  @override
  String get labelDuration => 'Trajanje';

  @override
  String get labelPet => 'Ljubimac';

  @override
  String get labelPrice => 'Cijena';

  @override
  String get labelName => 'Naziv';

  @override
  String get labelAddress => 'Adresa';

  @override
  String get labelPhone => 'Telefon';

  @override
  String get servicesWithSpecialist => 'Usluge kod ovog specijaliste';

  @override
  String get noServicesListed => 'Još nema navedenih usluga.';

  @override
  String get reviewsForSpecialist => 'Recenzije za ovog specijalistu';

  @override
  String get amenityInOffice => 'Pregledi u ordinaciji';

  @override
  String get amenityInOfficeDesc =>
      'Ova klinika prima ljubimce direktno u svojoj ordinaciji.';

  @override
  String get amenityOnField => 'Terenske posjete';

  @override
  String get amenityOnFieldDesc => 'Veterinar može doći na vašu kućnu adresu.';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityParkingDesc => 'Besplatan parking dostupan za posjetioce.';

  @override
  String get amenityWheelchair => 'Pristup za invalidska kolica';

  @override
  String get amenityWheelchairDesc =>
      'Objekat je prilagođen osobama sa invaliditetom.';

  @override
  String get amenityWifi => 'Besplatan WiFi';

  @override
  String get amenityWifiDesc =>
      'Besplatan bežični internet dostupan u čekaonici.';

  @override
  String get roleVeterinarian => 'Veterinar';

  @override
  String get roleNurse => 'Medicinska sestra';

  @override
  String get roleGroomer => 'Njegovatelj/ica';

  @override
  String get roleMainVet => 'Glavni veterinar';

  @override
  String get roleNoPreference => 'Bez preferencije';

  @override
  String get serviceVaccinationName => 'Vakcinacija';

  @override
  String get serviceVaccinationDesc =>
      'Osnovne vakcine i vakcina protiv bjesnila';

  @override
  String get serviceCheckupName => 'Opći pregled';

  @override
  String get serviceCheckupDesc => 'Kompletan fizički pregled';

  @override
  String get serviceDentalName => 'Čišćenje zuba';

  @override
  String get serviceDentalDesc => 'Skidanje kamenca i poliranje';

  @override
  String get serviceGroomingName => 'Šišanje i njega';

  @override
  String get serviceGroomingDesc => 'Pranje, šišanje i njega noktiju';
}
