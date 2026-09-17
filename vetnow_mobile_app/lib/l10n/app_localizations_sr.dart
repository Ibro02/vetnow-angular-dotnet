// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get navExplore => 'Istraži';

  @override
  String get navAppointments => 'Termini';

  @override
  String get navProfile => 'Profil';

  @override
  String get exploreHeroTitle => 'Pouzdana nega,\nzakazana za sekunde.';

  @override
  String get exploreHeroSubtitle =>
      'Pregledaj proverene klinike blizu tebe — bez naloga za pregledanje.';

  @override
  String get searchHint => 'Pretraži klinike…';

  @override
  String get clearSearch => 'Obriši pretragu';

  @override
  String get filterRecommended => 'Preporučeno';

  @override
  String get filterTopRated => 'Najbolje ocenjeno';

  @override
  String clinicsInCity(int count, String city) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klinika u $city',
      few: '$count klinike u $city',
      one: '$count klinika u $city',
    );
    return '$_temp0';
  }

  @override
  String get noClinicsMatch => 'Nijedna klinika ne odgovara tvojim filterima';

  @override
  String get chooseCity => 'Izaberi grad';

  @override
  String get sessionExpired => 'Sesija je istekla. Prijavite se ponovo.';

  @override
  String get validationFirstNameRequired => 'Unesi ime';

  @override
  String get validationLastNameRequired => 'Unesi prezime';

  @override
  String get validationNameTooShort => 'Najmanje 2 slova';

  @override
  String get validationEmailRequired => 'Unesi email adresu';

  @override
  String get validationEmailInvalid => 'Ovo ne izgleda kao email adresa';

  @override
  String get validationPhoneInvalid => 'Samo brojevi, razmaci i +';

  @override
  String get validationPhoneTooShort => 'Broj je prekratak';

  @override
  String get validationPasswordTooShort =>
      'Lozinka mora imati najmanje 8 znakova';

  @override
  String validationCheckFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Proveri još $count polja',
      few: 'Proveri još $count polja',
      one: 'Proveri još $count polje',
    );
    return '$_temp0';
  }

  @override
  String get calendarOpen => 'Kalendar';

  @override
  String get pickDay => 'Izaberi dan';

  @override
  String get monthSheetTitle => 'Izaberi datum';

  @override
  String get dayPartMorning => 'Jutro';

  @override
  String get dayPartAfternoon => 'Popodne';

  @override
  String get dayPartEvening => 'Veče';

  @override
  String get dayPartFull => 'popunjeno';

  @override
  String get closedShort => 'zatv.';

  @override
  String get earliestLabel => 'Najranije slobodno';

  @override
  String get todayWord => 'danas';

  @override
  String get tomorrowWord => 'sutra';

  @override
  String pickTimeOnDay(Object date) {
    return 'Odaberi vreme $date';
  }

  @override
  String noSlotsOnDay(Object date) {
    return 'Nema slobodnih termina $date.';
  }

  @override
  String nextFreeDay(Object date) {
    return 'Prvi slobodan: $date';
  }

  @override
  String slotAtDuration(Object date, Object slot, Object duration) {
    return '$date u $slot · $duration min';
  }

  @override
  String get firstOnDay => 'Prvi termin';

  @override
  String get allCities => 'Svi gradovi';

  @override
  String get noRatingsYet => 'Nova';

  @override
  String get noReviewsYet => 'Još nema recenzija';

  @override
  String get beFirstToReview => 'Budi prvi koji će ocijeniti ovu kliniku.';

  @override
  String get rateYourVisit => 'Ocijeni svoju posjetu';

  @override
  String get rateVisitHint => 'Bio si ovdje — kako je prošlo?';

  @override
  String get reviewCommentHint => 'Napiši par riječi (nije obavezno)';

  @override
  String get submitReview => 'Pošalji recenziju';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recenzija',
      few: '$count recenzije',
      one: '$count recenzija',
    );
    return '$_temp0';
  }

  @override
  String visitOn(String date) {
    return 'Posjeta $date';
  }

  @override
  String get clinicReviews => 'Recenzije klinike';

  @override
  String get pickRating => 'Odaberi ocjenu';

  @override
  String get couldNotOpenMaps => 'Ne mogu otvoriti mape na ovom uređaju.';

  @override
  String ageYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godina',
      few: '$count godine',
      one: '$count godina',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mjeseci',
      few: '$count mjeseca',
      one: '$count mjesec',
    );
    return '$_temp0';
  }

  @override
  String get ageUnknown => 'Starost nepoznata';

  @override
  String get birthdayToday => 'Rođendan danas!';

  @override
  String birthdayInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rođendan za $count dana',
      few: 'Rođendan za $count dana',
      one: 'Rođendan za $count dan',
    );
    return '$_temp0';
  }

  @override
  String turnsAge(String name, String age) {
    return '$name puni $age';
  }

  @override
  String get notificationsBirthdays => 'Rođendani';

  @override
  String get dayMonday => 'Ponedjeljak';

  @override
  String get dayTuesday => 'Utorak';

  @override
  String get dayWednesday => 'Srijeda';

  @override
  String get dayThursday => 'Četvrtak';

  @override
  String get dayFriday => 'Petak';

  @override
  String get daySaturday => 'Subota';

  @override
  String get daySunday => 'Nedjelja';

  @override
  String get closedDay => 'Zatvoreno';

  @override
  String get openNowLabel => 'Otvoreno sada';

  @override
  String get closedNowLabel => 'Trenutno zatvoreno';

  @override
  String get openingHours => 'Radno vrijeme';

  @override
  String get noScheduleYet => 'Radno vrijeme još nije uneseno.';

  @override
  String get notificationsEmpty => 'Sve je čisto — nema ničega novog.';

  @override
  String get notificationsUpcoming => 'Nadolazeći termini';

  @override
  String get notificationsAwaitingReview => 'Čekaju tvoju ocjenu';

  @override
  String get notificationsRateCta => 'Ocijeni';

  @override
  String get notificationsGuest =>
      'Prijavi se da vidiš svoje termine i podsjetnike.';

  @override
  String todayAt(String time) {
    return 'Danas u $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Sutra u $time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date u $time';
  }

  @override
  String get somethingWentWrong => 'Nešto je pošlo po zlu';

  @override
  String get offlineShowingSaved =>
      'Nema veze sa serverom — prikazane su zadnje sačuvane klinike.';

  @override
  String get sortByName => 'Po imenu';

  @override
  String get sortDefault => 'Redoslijed';

  @override
  String get filterMostReviewed => 'Najviše recenzija';

  @override
  String clinicsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pronađenih klinika',
      few: '$count pronađene klinike',
      one: '$count pronađena klinika',
    );
    return '$_temp0';
  }

  @override
  String get loginTitle => 'Prijava';

  @override
  String get loginBookingGateTitle => 'Skoro gotovo';

  @override
  String get loginBookingGateSubtitle =>
      'Prijavi se da potvrdiš termin — traje sekund.';

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
      'Nalog nije verifikovan. Poslali smo novi kod na tvoj email.';

  @override
  String get networkError =>
      'Nešto nije uspelo. Proveri internet konekciju i pokušaj ponovo.';

  @override
  String get retry => 'Pokušaj ponovo';

  @override
  String get registerSuccessCheckEmail =>
      'Nalog je kreiran! Proveri email da ga verifikuješ, pa se prijavi.';

  @override
  String get passwordRequirementsHint =>
      'Najmanje 8 znakova: veliko i malo slovo, broj i specijalni znak.';

  @override
  String get noAccount => 'Nemaš nalog?';

  @override
  String get register => 'Registruj se';

  @override
  String get createAccount => 'Napravi nalog';

  @override
  String get registerSubtitle =>
      'Napravi nalog da zakazuješ termine i upravljaš ljubimcima.';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Prezime';

  @override
  String get email => 'Email';

  @override
  String get username => 'Korisničko ime';

  @override
  String get createAccountButton => 'Napravi nalog';

  @override
  String get backToLogin => 'Nazad na prijavu';

  @override
  String get myAppointments => 'Moji termini';

  @override
  String get appointmentsSubtitle => 'Prati svoje buduće i prošle posete';

  @override
  String get upcoming => 'Budući';

  @override
  String get pastVisits => 'Prošle posete';

  @override
  String get statusCompleted => 'Završeno';

  @override
  String get statusCancelled => 'Otkazano';

  @override
  String get noUpcoming => 'Nema budućih termina.';

  @override
  String get noPast => 'Istorija termina još nije dostupna.';

  @override
  String get noAppointmentsYet => 'Još nema termina';

  @override
  String get profileTitle => 'Profil';

  @override
  String get guestTitle => 'Pregledaš kao gost';

  @override
  String get guestMessage =>
      'Napravi nalog da sačuvaš svoje ljubimce, pratiš istoriju poseta i brže zakažeš sledeći put.';

  @override
  String get guestBenefit1 =>
      'Sačuvaj podatke o ljubimcima jednom, koristi za svaku rezervaciju';

  @override
  String get guestBenefit2 => 'Vodi evidenciju svake posete i vakcinacije';

  @override
  String get guestBenefit3 => 'Preskoči ponovno unošenje podataka sledeći put';

  @override
  String get logInRegister => 'Prijava / Registracija';

  @override
  String get takesLessThanMinute => 'Traje manje od minuta.';

  @override
  String get myPets => 'Moji ljubimci';

  @override
  String get viewAll => 'Pogledaj sve';

  @override
  String get addPet => 'Dodaj ljubimca';

  @override
  String get account => 'Nalog';

  @override
  String get personalInfo => 'Lični podaci';

  @override
  String get passwordSecurity => 'Lozinka i bezbednost';

  @override
  String get notifications => 'Obaveštenja';

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
      'Uvek možeš ponovo da se prijaviš da vidiš svoje ljubimce i termine.';

  @override
  String get stayLoggedIn => 'Ostani prijavljen/a';

  @override
  String get cancelAppointmentTitle => 'Otkazati termin?';

  @override
  String get cancelAppointmentMessage =>
      'Ovo ne može da se poništi. Moraćeš da zakažeš novi termin ako se predomisliš.';

  @override
  String get keepIt => 'Zadrži';

  @override
  String get cancelAppointmentAction => 'Otkaži termin';

  @override
  String get reschedule => 'Promeni termin';

  @override
  String get bookAgain => 'Zakaži ponovo';

  @override
  String get bookAppointment => 'Zakaži termin';

  @override
  String get chooseService => 'Izaberi uslugu';

  @override
  String get chooseStaffOptional => 'Izaberi osoblje (opciono)';

  @override
  String get pickTimeToday => 'Izaberi vreme — danas';

  @override
  String get pickTimeAbove => 'Izaberi vreme iznad';

  @override
  String get choosePet => 'Izaberi ljubimca';

  @override
  String get noPetsYet => 'Nemaš dodatih ljubimaca.';

  @override
  String get addPetFirst => 'Dodaj ljubimca da nastaviš';

  @override
  String get bookingFailed =>
      'Rezervacija nije uspela — termin je možda upravo zauzet. Pokušaj ponovo.';

  @override
  String get anyAvailable => 'Bilo ko dostupan';

  @override
  String get confirmBooking => 'Potvrdi rezervaciju';

  @override
  String get selectServiceAndTime => 'Izaberi uslugu i vreme';

  @override
  String get bookingSummary => 'Pregled rezervacije';

  @override
  String get total => 'Ukupno';

  @override
  String get youAreBooked => 'Zakazano je!';

  @override
  String bookingConfirmedMessage(String clinicName) {
    return 'Tvoj termin u $clinicName je potvrđen. Poslali smo detalje na tvoj email.';
  }

  @override
  String get backToExplore => 'Nazad na Istraži';

  @override
  String get call => 'Pozovi';

  @override
  String get book => 'Zakaži';

  @override
  String get verifiedPartner => 'Verifikovani partner';

  @override
  String get whatIsVerifiedPartner => 'Šta znači Verifikovani partner?';

  @override
  String get verifiedPartnerExplanation =>
      'Licenca ove klinike je proverena u registru Veterinarske komore, a njeno osoblje i usluge prikazane ovde pregledao je VetNow tim.';

  @override
  String get gotIt => 'Razumem';

  @override
  String get meetTheTeam => 'Upoznaj tim';

  @override
  String get allServices => 'Sve usluge';

  @override
  String get reviews => 'Recenzije';

  @override
  String get openNow => 'Otvoreno sada';

  @override
  String get language => 'Jezik';

  @override
  String get appearance => 'Izgled';

  @override
  String get themeSystem => 'Kao na uređaju';

  @override
  String get themeLight => 'Svijetla';

  @override
  String get themeDark => 'Tamna';

  @override
  String get chooseTheme => 'Odaberi izgled';

  @override
  String get chooseLanguage => 'Izaberi jezik';

  @override
  String get bosnian => 'Bosanski';

  @override
  String get croatian => 'Hrvatski';

  @override
  String get serbian => 'Srpski';

  @override
  String get savePet => 'Sačuvaj ljubimca';

  @override
  String get saveChanges => 'Sačuvaj izmene';

  @override
  String get editPet => 'Izmeni ljubimca';

  @override
  String get favourites => 'Omiljeni';

  @override
  String get addToFavourites => 'Dodaj u omiljene';

  @override
  String get removeFromFavourites => 'Ukloni iz omiljenih';

  @override
  String get mostVisited => 'Najčešće dolazi';

  @override
  String get visits => 'termina';

  @override
  String get markFavourite => 'Označi kao omiljenog';

  @override
  String get unmarkFavourite => 'Ukloni iz omiljenih';

  @override
  String get petsDashboardSubtitle => 'Tvoji ljubimci, na jednom mestu';

  @override
  String get viewList => 'Lista';

  @override
  String get viewDashboard => 'Dashboard';

  @override
  String get searchPetsHint => 'Pretraži po imenu…';

  @override
  String get filterAllSpecies => 'Sve vrste';

  @override
  String get noPetsMatchFilter => 'Nijedan ljubimac ne odgovara pretrazi.';

  @override
  String get dragWholeCardHint =>
      'Drži karticu i prevuci da promeniš redosled.';

  @override
  String get chooseSpecies => 'Izaberi vrstu';

  @override
  String get searchSpeciesHint => 'Pretraži vrste…';

  @override
  String get noSpeciesFound => 'Nema pronađenih vrsta.';

  @override
  String approxAge(String age) {
    return 'Star/a otprilike $age';
  }

  @override
  String get selectBirthDate => 'Izaberi datum';

  @override
  String get tellUsAboutFriend => 'Reci nam o svom prijatelju';

  @override
  String get weightOptional => 'Težina (kg) — opciono';

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
  String get deletePetConfirmMessage => 'Ovo ne može da se poništi.';

  @override
  String get deletePetAction => 'Ukloni';

  @override
  String get details => 'Detalji';

  @override
  String get vaccinationHistory => 'Istorija vakcinacije';

  @override
  String get noVaccinationRecords =>
      'Još nema zapisa o vakcinaciji.\nTvoja veterinarska stanica ih može dodati posle posete.';

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
  String get labelPrice => 'Cena';

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
  String get amenityInOffice => 'Pregledi u ordinaciji';

  @override
  String get amenityInOfficeDesc =>
      'Ova klinika prima ljubimce direktno u svojoj ordinaciji.';

  @override
  String get amenityOnField => 'Terenske posete';

  @override
  String get amenityOnFieldDesc => 'Veterinar može doći na vašu kućnu adresu.';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityParkingDesc => 'Besplatan parking dostupan za posetioce.';

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
  String get filterClinics => 'Filtriraj klinike';

  @override
  String get applyFilters => 'Primeni';

  @override
  String get resetFilters => 'Poništi';

  @override
  String get trustNoAccount => 'Bez naloga za gledanje';

  @override
  String get trustFewTaps => 'Rezervacija za par klikova';

  @override
  String get roleVeterinarian => 'Veterinar';

  @override
  String get roleNurse => 'Medicinska sestra';

  @override
  String get roleGroomer => 'Negovatelj/ica';

  @override
  String get roleNoPreference => 'Bez preferencije';

  @override
  String get serviceVaccinationName => 'Vakcinacija';

  @override
  String get serviceVaccinationDesc =>
      'Osnovne vakcine i vakcina protiv besnila';

  @override
  String get serviceCheckupName => 'Opšti pregled';

  @override
  String get serviceCheckupDesc => 'Kompletan fizički pregled';

  @override
  String get serviceDentalName => 'Čišćenje zuba';

  @override
  String get serviceDentalDesc => 'Skidanje kamenca i poliranje';

  @override
  String get serviceGroomingName => 'Šišanje i nega';

  @override
  String get staffBioInternal =>
      'Fokus na internu medicinu i preventivnu negu, 9 godina prakse.';

  @override
  String get staffBioSurgery =>
      'Vodeći hirurg — stomatološki i zahvati na mekim tkivima.';

  @override
  String get staffBioGrooming =>
      'Šišanje i nega noktiju za pse i mačke svih veličina.';

  @override
  String get serviceGroomingDesc => 'Pranje, šišanje i nega noktiju';

  @override
  String get currentAppointment => 'Trenutni termin';

  @override
  String get noFreeSlotsThatDay =>
      'Nema slobodnih termina za taj dan. Probaj drugi datum.';

  @override
  String get confirmReschedule => 'Potvrdi novi termin';

  @override
  String get rescheduleSuccess => 'Termin je pomeren.';

  @override
  String get editProfile => 'Uredi profil';

  @override
  String get editProfileSubtitle => 'Ažuriraj svoje podatke i lozinku';

  @override
  String get profileUpdated => 'Profil je ažuriran.';

  @override
  String get sectionPersonalInfo => 'Lični podaci';

  @override
  String get sectionContact => 'Kontakt';

  @override
  String get sectionLocation => 'Lokacija';

  @override
  String get sectionSecurity => 'Bezbednost';

  @override
  String get labelCity => 'Grad';

  @override
  String get labelCountry => 'Država';

  @override
  String get newPassword => 'Nova lozinka';

  @override
  String get newPasswordHint => 'Ostavi prazno ako je ne menjaš';

  @override
  String get couldNotPlaceCall =>
      'Poziv nije moguće pokrenuti sa ovog uređaja.';

  @override
  String get verifyAccountTitle => 'Potvrda naloga';

  @override
  String get verifyAccountHeadline => 'Proveri svoj email';

  @override
  String get verifyAccountBody =>
      'Poslali smo ti kod za potvrdu. Upiši ga ispod da aktiviraš nalog.';

  @override
  String verifyAccountBodyFor(String contact) {
    return 'Poslali smo kod za potvrdu na $contact. Upiši ga ispod da aktiviraš nalog.';
  }

  @override
  String get verifyAccountAction => 'Potvrdi nalog';

  @override
  String get verifyAccountResendHint =>
      'Nisi dobio kod? Pokušaj da se prijaviš ponovo — novi kod šaljemo pri svakoj prijavi.';

  @override
  String get filterAllStaff => 'Svi';

  @override
  String get a11yLoading => 'Učitavanje';

  @override
  String get a11yBack => 'Nazad';

  @override
  String get a11yClearSearch => 'Obriši pretragu';

  @override
  String get a11yShowPassword => 'Prikaži lozinku';

  @override
  String get a11yHidePassword => 'Sakrij lozinku';

  @override
  String a11yRateStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zvezdica',
      few: '$count zvezdice',
      one: '$count zvezdica',
    );
    return '$_temp0';
  }

  @override
  String get diagnosticsTitle => 'Pomoć i dijagnostika';

  @override
  String get diagnosticsAbout => 'O aplikaciji';

  @override
  String get diagnosticsVersion => 'Verzija';

  @override
  String get diagnosticsBackend => 'Server';

  @override
  String get diagnosticsReports => 'Zapisi o greškama';

  @override
  String get diagnosticsEmpty => 'Nema zabeleženih grešaka. To je dobra vest.';

  @override
  String get diagnosticsExplainer =>
      'Ako nešto krene po zlu, aplikacija to zabeleži ovde — samo na tvom telefonu, ništa se ne šalje. Kopiraj i pošalji nam kad prijavljuješ problem.';

  @override
  String get diagnosticsCopy => 'Kopiraj izvještaj';

  @override
  String get diagnosticsCopied => 'Kopirano';

  @override
  String get diagnosticsClear => 'Obriši zapise';

  @override
  String get diagnosticsCleared => 'Zapisi obrisani';

  @override
  String get diagnosticsFatal => 'Pad';

  @override
  String get diagnosticsHandled => 'Greška';

  @override
  String get configWarningTitle => 'Ovaj build nije spreman za objavu';

  @override
  String get configWarningBody =>
      'Aplikacija je podešena da priča sa serverom koji postoji samo na računaru na kojem je build napravljen, pa ništa neće raditi na telefonu. Ponovo napravi build sa --dart-define=API_BASE_URL=https://…';

  @override
  String get reportReview => 'Prijavi recenziju';

  @override
  String get reportReviewTitle => 'Prijaviti ovu recenziju?';

  @override
  String get reportReviewBody =>
      'Otvorićemo e-mail s detaljima recenzije da ga pošalješ. Pregledamo svaku prijavu i uklanjamo sadržaj koji krši pravila.';

  @override
  String get reportReviewSend => 'Otvori e-mail';

  @override
  String get reportReviewFailed =>
      'Nismo mogli otvoriti e-mail aplikaciju. Kontakt adresa je kopirana.';

  @override
  String get forgotPasswordTitle => 'Zaboravljena lozinka';

  @override
  String forgotPasswordBody(String email) {
    return 'Resetovanje lozinke još nije dostupno u aplikaciji. Javi nam se na $email i vratićemo ti pristup.';
  }

  @override
  String get copyEmail => 'Kopiraj adresu';

  @override
  String get copied => 'Kopirano';
}
