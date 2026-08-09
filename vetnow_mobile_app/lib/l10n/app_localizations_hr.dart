// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'VetNow';

  @override
  String get navExplore => 'Istraži';

  @override
  String get navAppointments => 'Termini';

  @override
  String get navProfile => 'Profil';

  @override
  String get exploreHeroTitle => 'Pouzdana skrb,\nrezervirana za sekunde.';

  @override
  String get exploreHeroSubtitle =>
      'Pregledaj provjerene klinike blizu tebe — bez računa za pregledavanje.';

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
    return '$count klinika u gradu $city';
  }

  @override
  String get noClinicsMatch => 'Nijedna klinika ne odgovara tvojim filterima';

  @override
  String get chooseCity => 'Odaberi grad';

  @override
  String get loginTitle => 'Prijava';

  @override
  String get loginBookingGateTitle => 'Gotovo';

  @override
  String get loginBookingGateSubtitle =>
      'Prijavi se za potvrdu termina — traje sekundu.';

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
      'Račun nije verificiran. Poslali smo novi kod na tvoj email.';

  @override
  String get networkError =>
      'Nešto nije uspjelo. Provjeri internetsku vezu i pokušaj ponovno.';

  @override
  String get retry => 'Pokušaj ponovno';

  @override
  String get registerSuccessCheckEmail =>
      'Račun je kreiran! Provjeri email da ga verificiraš, pa se prijavi.';

  @override
  String get passwordRequirementsHint =>
      'Najmanje 8 znakova: veliko i malo slovo, broj i specijalni znak.';

  @override
  String get noAccount => 'Nemaš račun?';

  @override
  String get register => 'Registriraj se';

  @override
  String get createAccount => 'Izradi račun';

  @override
  String get registerSubtitle =>
      'Izradi račun kako bi rezervirao/la termine i upravljao/la ljubimcima.';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Prezime';

  @override
  String get email => 'Email';

  @override
  String get username => 'Korisničko ime';

  @override
  String get createAccountButton => 'Izradi račun';

  @override
  String get backToLogin => 'Natrag na prijavu';

  @override
  String get myAppointments => 'Moji termini';

  @override
  String get appointmentsSubtitle => 'Prati svoje nadolazeće i prošle posjete';

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
  String get guestTitle => 'Pregledavaš kao gost';

  @override
  String get guestMessage =>
      'Izradi račun kako bi spremio/la svoje ljubimce, pratio/la povijest posjeta i brže rezervirao/la sljedeći put.';

  @override
  String get guestBenefit1 =>
      'Spremi podatke o ljubimcima jednom, koristi za svaku rezervaciju';

  @override
  String get guestBenefit2 => 'Vodi evidenciju svake posjete i cijepljenja';

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
  String get personalInfo => 'Osobni podaci';

  @override
  String get passwordSecurity => 'Lozinka i sigurnost';

  @override
  String get notifications => 'Obavijesti';

  @override
  String get helpSupport => 'Pomoć i podrška';

  @override
  String get logOut => 'Odjava';

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
      'Uvijek se možeš ponovno prijaviti kako bi vidio/la svoje ljubimce i termine.';

  @override
  String get stayLoggedIn => 'Ostani prijavljen/a';

  @override
  String get cancelAppointmentTitle => 'Otkazati termin?';

  @override
  String get cancelAppointmentMessage =>
      'Ovo se ne može poništiti. Trebat ćeš rezervirati novi termin ako se predomisliš.';

  @override
  String get keepIt => 'Zadrži';

  @override
  String get cancelAppointmentAction => 'Otkaži termin';

  @override
  String get reschedule => 'Promijeni termin';

  @override
  String get bookAgain => 'Rezerviraj ponovno';

  @override
  String get bookAppointment => 'Rezerviraj termin';

  @override
  String get chooseService => 'Odaberi uslugu';

  @override
  String get chooseStaffOptional => 'Odaberi osoblje (neobavezno)';

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
      'Rezervacija nije uspjela — termin je možda upravo zauzet. Pokušaj ponovno.';

  @override
  String get signInToSeeRealAvailability =>
      'Prijavljen/a si — sad biraš iz stvarno dostupnog osoblja i termina.';

  @override
  String get anyAvailable => 'Bilo tko dostupan';

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
  String get youAreBooked => 'Rezervirano je!';

  @override
  String bookingConfirmedMessage(String clinicName) {
    return 'Tvoj termin u $clinicName je potvrđen. Poslali smo detalje na tvoj email.';
  }

  @override
  String get backToExplore => 'Natrag na Istraži';

  @override
  String get call => 'Nazovi';

  @override
  String get book => 'Rezerviraj';

  @override
  String get verifiedPartner => 'Verificirani partner';

  @override
  String get whatIsVerifiedPartner => 'Što znači Verificirani partner?';

  @override
  String get verifiedPartnerExplanation =>
      'Licenca ove klinike provjerena je u registru Veterinarske komore, a njezino osoblje i usluge prikazane ovdje pregledao je VetNow tim.';

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
  String get savePet => 'Spremi ljubimca';

  @override
  String get tellUsAboutFriend => 'Reci nam o svom prijatelju';

  @override
  String get weightOptional => 'Težina (kg) — neobavezno';

  @override
  String get breed => 'Pasmina';

  @override
  String get species => 'Vrsta';

  @override
  String get petName => 'Ime';

  @override
  String get petInfoNote =>
      'Cijepljenja i druge detalje možeš dodati kasnije s profila ljubimca.';

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
  String get vaccinationHistory => 'Povijest cijepljenja';

  @override
  String get noVaccinationRecords =>
      'Još nema zapisa o cijepljenju.\nTvoja veterinarska klinika ih može dodati nakon posjeta.';

  @override
  String get weight => 'Težina';

  @override
  String get microchip => 'Mikročip';

  @override
  String get age => 'Dob';

  @override
  String get sectionAppointment => 'Termin';

  @override
  String get appointmentDetails => 'Detalji termina';

  @override
  String get sectionSpecialist => 'Specijalist';

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
  String get servicesWithSpecialist => 'Usluge kod ovog specijalista';

  @override
  String get noServicesListed => 'Još nema navedenih usluga.';

  @override
  String get reviewsForSpecialist => 'Recenzije za ovog specijalista';

  @override
  String get amenityInOffice => 'Pregledi u ordinaciji';

  @override
  String get amenityInOfficeDesc =>
      'Ova klinika prima ljubimce izravno u svojoj ordinaciji.';

  @override
  String get amenityOnField => 'Terenske posjete';

  @override
  String get amenityOnFieldDesc => 'Veterinar može doći na vašu kućnu adresu.';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityParkingDesc =>
      'Besplatan parking dostupan za posjetitelje.';

  @override
  String get amenityWheelchair => 'Pristup za invalidska kolica';

  @override
  String get amenityWheelchairDesc =>
      'Objekt je prilagođen osobama s invaliditetom.';

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
  String get serviceVaccinationName => 'Cijepljenje';

  @override
  String get serviceVaccinationDesc =>
      'Osnovna cjepiva i cjepivo protiv bjesnoće';

  @override
  String get serviceCheckupName => 'Opći pregled';

  @override
  String get serviceCheckupDesc => 'Kompletan fizički pregled';

  @override
  String get serviceDentalName => 'Čišćenje zubi';

  @override
  String get serviceDentalDesc => 'Skidanje kamenca i poliranje';

  @override
  String get serviceGroomingName => 'Šišanje i njega';

  @override
  String get serviceGroomingDesc => 'Pranje, šišanje i njega noktiju';
}
