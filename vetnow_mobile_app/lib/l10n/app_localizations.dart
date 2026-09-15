import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bs.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bs'),
    Locale('hr'),
    Locale('sr')
  ];

  /// No description provided for @navExplore.
  ///
  /// In bs, this message translates to:
  /// **'Istraži'**
  String get navExplore;

  /// No description provided for @navAppointments.
  ///
  /// In bs, this message translates to:
  /// **'Termini'**
  String get navAppointments;

  /// No description provided for @navProfile.
  ///
  /// In bs, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @exploreHeroTitle.
  ///
  /// In bs, this message translates to:
  /// **'Pouzdana njega,\nrezervisana za sekunde.'**
  String get exploreHeroTitle;

  /// No description provided for @exploreHeroSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Pregledaj provjerene klinike blizu tebe — bez računa za pregledanje.'**
  String get exploreHeroSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In bs, this message translates to:
  /// **'Pretraži klinike…'**
  String get searchHint;

  /// No description provided for @filterRecommended.
  ///
  /// In bs, this message translates to:
  /// **'Preporučeno'**
  String get filterRecommended;

  /// No description provided for @filterTopRated.
  ///
  /// In bs, this message translates to:
  /// **'Najbolje ocijenjeno'**
  String get filterTopRated;

  /// No description provided for @clinicsInCity.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{{count} klinika u {city}} few{{count} klinike u {city}} other{{count} klinika u {city}}}'**
  String clinicsInCity(int count, String city);

  /// No description provided for @noClinicsMatch.
  ///
  /// In bs, this message translates to:
  /// **'Nijedna klinika ne odgovara tvojim filterima'**
  String get noClinicsMatch;

  /// No description provided for @chooseCity.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi grad'**
  String get chooseCity;

  /// No description provided for @allCities.
  ///
  /// In bs, this message translates to:
  /// **'Svi gradovi'**
  String get allCities;

  /// No description provided for @noRatingsYet.
  ///
  /// In bs, this message translates to:
  /// **'Nova'**
  String get noRatingsYet;

  /// No description provided for @noReviewsYet.
  ///
  /// In bs, this message translates to:
  /// **'Još nema recenzija'**
  String get noReviewsYet;

  /// No description provided for @beFirstToReview.
  ///
  /// In bs, this message translates to:
  /// **'Budi prvi koji će ocijeniti ovu kliniku.'**
  String get beFirstToReview;

  /// No description provided for @rateYourVisit.
  ///
  /// In bs, this message translates to:
  /// **'Ocijeni svoju posjetu'**
  String get rateYourVisit;

  /// No description provided for @rateVisitHint.
  ///
  /// In bs, this message translates to:
  /// **'Bio si ovdje — kako je prošlo?'**
  String get rateVisitHint;

  /// No description provided for @reviewCommentHint.
  ///
  /// In bs, this message translates to:
  /// **'Napiši par riječi (nije obavezno)'**
  String get reviewCommentHint;

  /// No description provided for @submitReview.
  ///
  /// In bs, this message translates to:
  /// **'Pošalji recenziju'**
  String get submitReview;

  /// No description provided for @reviewsCount.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{{count} recenzija} few{{count} recenzije} other{{count} recenzija}}'**
  String reviewsCount(int count);

  /// No description provided for @visitOn.
  ///
  /// In bs, this message translates to:
  /// **'Posjeta {date}'**
  String visitOn(String date);

  /// No description provided for @clinicReviews.
  ///
  /// In bs, this message translates to:
  /// **'Recenzije klinike'**
  String get clinicReviews;

  /// No description provided for @pickRating.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi ocjenu'**
  String get pickRating;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In bs, this message translates to:
  /// **'Ne mogu otvoriti mape na ovom uređaju.'**
  String get couldNotOpenMaps;

  /// No description provided for @ageYears.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{{count} godina} few{{count} godine} other{{count} godina}}'**
  String ageYears(int count);

  /// No description provided for @ageMonths.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{{count} mjesec} few{{count} mjeseca} other{{count} mjeseci}}'**
  String ageMonths(int count);

  /// No description provided for @ageUnknown.
  ///
  /// In bs, this message translates to:
  /// **'Starost nepoznata'**
  String get ageUnknown;

  /// No description provided for @birthdayToday.
  ///
  /// In bs, this message translates to:
  /// **'Rođendan danas!'**
  String get birthdayToday;

  /// No description provided for @birthdayInDays.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{Rođendan za {count} dan} few{Rođendan za {count} dana} other{Rođendan za {count} dana}}'**
  String birthdayInDays(int count);

  /// No description provided for @turnsAge.
  ///
  /// In bs, this message translates to:
  /// **'{name} puni {age}'**
  String turnsAge(String name, String age);

  /// No description provided for @notificationsBirthdays.
  ///
  /// In bs, this message translates to:
  /// **'Rođendani'**
  String get notificationsBirthdays;

  /// No description provided for @dayMonday.
  ///
  /// In bs, this message translates to:
  /// **'Ponedjeljak'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In bs, this message translates to:
  /// **'Utorak'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In bs, this message translates to:
  /// **'Srijeda'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In bs, this message translates to:
  /// **'Četvrtak'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In bs, this message translates to:
  /// **'Petak'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In bs, this message translates to:
  /// **'Subota'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In bs, this message translates to:
  /// **'Nedjelja'**
  String get daySunday;

  /// No description provided for @closedDay.
  ///
  /// In bs, this message translates to:
  /// **'Zatvoreno'**
  String get closedDay;

  /// No description provided for @openNowLabel.
  ///
  /// In bs, this message translates to:
  /// **'Otvoreno sada'**
  String get openNowLabel;

  /// No description provided for @closedNowLabel.
  ///
  /// In bs, this message translates to:
  /// **'Trenutno zatvoreno'**
  String get closedNowLabel;

  /// No description provided for @openingHours.
  ///
  /// In bs, this message translates to:
  /// **'Radno vrijeme'**
  String get openingHours;

  /// No description provided for @noScheduleYet.
  ///
  /// In bs, this message translates to:
  /// **'Radno vrijeme još nije uneseno.'**
  String get noScheduleYet;

  /// No description provided for @notificationsEmpty.
  ///
  /// In bs, this message translates to:
  /// **'Sve je čisto — nema ničega novog.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsUpcoming.
  ///
  /// In bs, this message translates to:
  /// **'Nadolazeći termini'**
  String get notificationsUpcoming;

  /// No description provided for @notificationsAwaitingReview.
  ///
  /// In bs, this message translates to:
  /// **'Čekaju tvoju ocjenu'**
  String get notificationsAwaitingReview;

  /// No description provided for @notificationsRateCta.
  ///
  /// In bs, this message translates to:
  /// **'Ocijeni'**
  String get notificationsRateCta;

  /// No description provided for @notificationsGuest.
  ///
  /// In bs, this message translates to:
  /// **'Prijavi se da vidiš svoje termine i podsjetnike.'**
  String get notificationsGuest;

  /// No description provided for @todayAt.
  ///
  /// In bs, this message translates to:
  /// **'Danas u {time}'**
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  ///
  /// In bs, this message translates to:
  /// **'Sutra u {time}'**
  String tomorrowAt(String time);

  /// No description provided for @dateAt.
  ///
  /// In bs, this message translates to:
  /// **'{date} u {time}'**
  String dateAt(String date, String time);

  /// No description provided for @somethingWentWrong.
  ///
  /// In bs, this message translates to:
  /// **'Nešto je pošlo po zlu'**
  String get somethingWentWrong;

  /// No description provided for @offlineShowingSaved.
  ///
  /// In bs, this message translates to:
  /// **'Nema veze sa serverom — prikazane su zadnje sačuvane klinike.'**
  String get offlineShowingSaved;

  /// No description provided for @sortByName.
  ///
  /// In bs, this message translates to:
  /// **'Po imenu'**
  String get sortByName;

  /// No description provided for @sortDefault.
  ///
  /// In bs, this message translates to:
  /// **'Redoslijed'**
  String get sortDefault;

  /// No description provided for @filterMostReviewed.
  ///
  /// In bs, this message translates to:
  /// **'Najviše recenzija'**
  String get filterMostReviewed;

  /// No description provided for @clinicsFound.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{{count} pronađena klinika} few{{count} pronađene klinike} other{{count} pronađenih klinika}}'**
  String clinicsFound(int count);

  /// No description provided for @loginTitle.
  ///
  /// In bs, this message translates to:
  /// **'Prijava'**
  String get loginTitle;

  /// No description provided for @loginBookingGateTitle.
  ///
  /// In bs, this message translates to:
  /// **'Skoro gotovo'**
  String get loginBookingGateTitle;

  /// No description provided for @loginBookingGateSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Prijavi se da potvrdiš termin — traje sekundu.'**
  String get loginBookingGateSubtitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Drago nam je da si opet tu! 🐾'**
  String get loginWelcomeSubtitle;

  /// No description provided for @usernameOrEmail.
  ///
  /// In bs, this message translates to:
  /// **'Korisničko ime / Email'**
  String get usernameOrEmail;

  /// No description provided for @password.
  ///
  /// In bs, this message translates to:
  /// **'Lozinka'**
  String get password;

  /// No description provided for @keepSignedIn.
  ///
  /// In bs, this message translates to:
  /// **'Ostani prijavljen/a'**
  String get keepSignedIn;

  /// No description provided for @forgotPassword.
  ///
  /// In bs, this message translates to:
  /// **'Zaboravljena lozinka?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In bs, this message translates to:
  /// **'Prijavi se'**
  String get signIn;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In bs, this message translates to:
  /// **'Pogrešno korisničko ime ili lozinka.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginNeedsVerification.
  ///
  /// In bs, this message translates to:
  /// **'Račun nije verifikovan. Poslali smo novi kod na tvoj email.'**
  String get loginNeedsVerification;

  /// No description provided for @networkError.
  ///
  /// In bs, this message translates to:
  /// **'Nešto nije uspjelo. Provjeri internet konekciju i pokušaj ponovo.'**
  String get networkError;

  /// No description provided for @retry.
  ///
  /// In bs, this message translates to:
  /// **'Pokušaj ponovo'**
  String get retry;

  /// No description provided for @registerSuccessCheckEmail.
  ///
  /// In bs, this message translates to:
  /// **'Račun je kreiran! Provjeri email da ga verifikuješ, pa se prijavi.'**
  String get registerSuccessCheckEmail;

  /// No description provided for @passwordRequirementsHint.
  ///
  /// In bs, this message translates to:
  /// **'Najmanje 8 znakova: veliko i malo slovo, broj i specijalni znak.'**
  String get passwordRequirementsHint;

  /// No description provided for @noAccount.
  ///
  /// In bs, this message translates to:
  /// **'Nemaš račun?'**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In bs, this message translates to:
  /// **'Registruj se'**
  String get register;

  /// No description provided for @createAccount.
  ///
  /// In bs, this message translates to:
  /// **'Kreiraj račun'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Kreiraj račun da rezervišeš termine i upravljaš ljubimcima.'**
  String get registerSubtitle;

  /// No description provided for @firstName.
  ///
  /// In bs, this message translates to:
  /// **'Ime'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In bs, this message translates to:
  /// **'Prezime'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In bs, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @username.
  ///
  /// In bs, this message translates to:
  /// **'Korisničko ime'**
  String get username;

  /// No description provided for @createAccountButton.
  ///
  /// In bs, this message translates to:
  /// **'Kreiraj račun'**
  String get createAccountButton;

  /// No description provided for @backToLogin.
  ///
  /// In bs, this message translates to:
  /// **'Nazad na prijavu'**
  String get backToLogin;

  /// No description provided for @myAppointments.
  ///
  /// In bs, this message translates to:
  /// **'Moji termini'**
  String get myAppointments;

  /// No description provided for @appointmentsSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Prati svoje buduće i prošle posjete'**
  String get appointmentsSubtitle;

  /// No description provided for @upcoming.
  ///
  /// In bs, this message translates to:
  /// **'Nadolazeći'**
  String get upcoming;

  /// No description provided for @pastVisits.
  ///
  /// In bs, this message translates to:
  /// **'Prošle posjete'**
  String get pastVisits;

  /// No description provided for @statusCompleted.
  ///
  /// In bs, this message translates to:
  /// **'Završeno'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In bs, this message translates to:
  /// **'Otkazano'**
  String get statusCancelled;

  /// No description provided for @noUpcoming.
  ///
  /// In bs, this message translates to:
  /// **'Nema nadolazećih termina.'**
  String get noUpcoming;

  /// No description provided for @noPast.
  ///
  /// In bs, this message translates to:
  /// **'Historija termina još nije dostupna.'**
  String get noPast;

  /// No description provided for @noAppointmentsYet.
  ///
  /// In bs, this message translates to:
  /// **'Još nema termina'**
  String get noAppointmentsYet;

  /// No description provided for @profileTitle.
  ///
  /// In bs, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @guestTitle.
  ///
  /// In bs, this message translates to:
  /// **'Pregledaš kao gost'**
  String get guestTitle;

  /// No description provided for @guestMessage.
  ///
  /// In bs, this message translates to:
  /// **'Kreiraj račun da sačuvaš svoje ljubimce, pratiš historiju posjeta i brže rezervišeš sljedeći put.'**
  String get guestMessage;

  /// No description provided for @guestBenefit1.
  ///
  /// In bs, this message translates to:
  /// **'Sačuvaj podatke o ljubimcima jednom, koristi za svaku rezervaciju'**
  String get guestBenefit1;

  /// No description provided for @guestBenefit2.
  ///
  /// In bs, this message translates to:
  /// **'Vodi evidenciju svake posjete i vakcinacije'**
  String get guestBenefit2;

  /// No description provided for @guestBenefit3.
  ///
  /// In bs, this message translates to:
  /// **'Preskoči ponovno unošenje podataka sljedeći put'**
  String get guestBenefit3;

  /// No description provided for @logInRegister.
  ///
  /// In bs, this message translates to:
  /// **'Prijava / Registracija'**
  String get logInRegister;

  /// No description provided for @takesLessThanMinute.
  ///
  /// In bs, this message translates to:
  /// **'Traje manje od minute.'**
  String get takesLessThanMinute;

  /// No description provided for @myPets.
  ///
  /// In bs, this message translates to:
  /// **'Moji ljubimci'**
  String get myPets;

  /// No description provided for @viewAll.
  ///
  /// In bs, this message translates to:
  /// **'Pogledaj sve'**
  String get viewAll;

  /// No description provided for @addPet.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj ljubimca'**
  String get addPet;

  /// No description provided for @account.
  ///
  /// In bs, this message translates to:
  /// **'Račun'**
  String get account;

  /// No description provided for @personalInfo.
  ///
  /// In bs, this message translates to:
  /// **'Lični podaci'**
  String get personalInfo;

  /// No description provided for @passwordSecurity.
  ///
  /// In bs, this message translates to:
  /// **'Lozinka i sigurnost'**
  String get passwordSecurity;

  /// No description provided for @notifications.
  ///
  /// In bs, this message translates to:
  /// **'Obavještenja'**
  String get notifications;

  /// No description provided for @helpSupport.
  ///
  /// In bs, this message translates to:
  /// **'Pomoć i podrška'**
  String get helpSupport;

  /// No description provided for @logOut.
  ///
  /// In bs, this message translates to:
  /// **'Odjavi se'**
  String get logOut;

  /// No description provided for @member.
  ///
  /// In bs, this message translates to:
  /// **'Član'**
  String get member;

  /// No description provided for @memberSince.
  ///
  /// In bs, this message translates to:
  /// **'Član od'**
  String get memberSince;

  /// No description provided for @pets.
  ///
  /// In bs, this message translates to:
  /// **'Ljubimci'**
  String get pets;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In bs, this message translates to:
  /// **'Odjava?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In bs, this message translates to:
  /// **'Uvijek se možeš ponovo prijaviti da vidiš svoje ljubimce i termine.'**
  String get logOutConfirmMessage;

  /// No description provided for @stayLoggedIn.
  ///
  /// In bs, this message translates to:
  /// **'Ostani prijavljen/a'**
  String get stayLoggedIn;

  /// No description provided for @cancelAppointmentTitle.
  ///
  /// In bs, this message translates to:
  /// **'Otkazati termin?'**
  String get cancelAppointmentTitle;

  /// No description provided for @cancelAppointmentMessage.
  ///
  /// In bs, this message translates to:
  /// **'Ovo se ne može poništiti. Trebat ćeš rezervisati novi termin ako se predomisliš.'**
  String get cancelAppointmentMessage;

  /// No description provided for @keepIt.
  ///
  /// In bs, this message translates to:
  /// **'Zadrži'**
  String get keepIt;

  /// No description provided for @cancelAppointmentAction.
  ///
  /// In bs, this message translates to:
  /// **'Otkaži termin'**
  String get cancelAppointmentAction;

  /// No description provided for @reschedule.
  ///
  /// In bs, this message translates to:
  /// **'Promijeni termin'**
  String get reschedule;

  /// No description provided for @bookAgain.
  ///
  /// In bs, this message translates to:
  /// **'Rezerviši ponovo'**
  String get bookAgain;

  /// No description provided for @bookAppointment.
  ///
  /// In bs, this message translates to:
  /// **'Rezerviši termin'**
  String get bookAppointment;

  /// No description provided for @chooseService.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi uslugu'**
  String get chooseService;

  /// No description provided for @chooseStaffOptional.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi osoblje (opcionalno)'**
  String get chooseStaffOptional;

  /// No description provided for @pickTimeToday.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi vrijeme — danas'**
  String get pickTimeToday;

  /// No description provided for @pickTimeAbove.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi vrijeme iznad'**
  String get pickTimeAbove;

  /// No description provided for @choosePet.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi ljubimca'**
  String get choosePet;

  /// No description provided for @noPetsYet.
  ///
  /// In bs, this message translates to:
  /// **'Nemaš dodanih ljubimaca.'**
  String get noPetsYet;

  /// No description provided for @addPetFirst.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj ljubimca da nastaviš'**
  String get addPetFirst;

  /// No description provided for @noSlotsToday.
  ///
  /// In bs, this message translates to:
  /// **'Nema slobodnih termina danas kod ovog zaposlenika.'**
  String get noSlotsToday;

  /// No description provided for @bookingFailed.
  ///
  /// In bs, this message translates to:
  /// **'Rezervacija nije uspjela — termin je možda upravo zauzet. Pokušaj ponovo.'**
  String get bookingFailed;

  /// No description provided for @anyAvailable.
  ///
  /// In bs, this message translates to:
  /// **'Bilo ko dostupan'**
  String get anyAvailable;

  /// No description provided for @confirmBooking.
  ///
  /// In bs, this message translates to:
  /// **'Potvrdi rezervaciju'**
  String get confirmBooking;

  /// No description provided for @selectServiceAndTime.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi uslugu i vrijeme'**
  String get selectServiceAndTime;

  /// No description provided for @bookingSummary.
  ///
  /// In bs, this message translates to:
  /// **'Pregled rezervacije'**
  String get bookingSummary;

  /// No description provided for @todayAtDuration.
  ///
  /// In bs, this message translates to:
  /// **'Danas u {slot} · {duration} min'**
  String todayAtDuration(String slot, int duration);

  /// No description provided for @total.
  ///
  /// In bs, this message translates to:
  /// **'Ukupno'**
  String get total;

  /// No description provided for @youAreBooked.
  ///
  /// In bs, this message translates to:
  /// **'Rezervisano je!'**
  String get youAreBooked;

  /// No description provided for @bookingConfirmedMessage.
  ///
  /// In bs, this message translates to:
  /// **'Tvoj termin u {clinicName} je potvrđen. Poslali smo detalje na tvoj email.'**
  String bookingConfirmedMessage(String clinicName);

  /// No description provided for @backToExplore.
  ///
  /// In bs, this message translates to:
  /// **'Nazad na Istraži'**
  String get backToExplore;

  /// No description provided for @call.
  ///
  /// In bs, this message translates to:
  /// **'Pozovi'**
  String get call;

  /// No description provided for @book.
  ///
  /// In bs, this message translates to:
  /// **'Rezerviši'**
  String get book;

  /// No description provided for @verifiedPartner.
  ///
  /// In bs, this message translates to:
  /// **'Verifikovani partner'**
  String get verifiedPartner;

  /// No description provided for @whatIsVerifiedPartner.
  ///
  /// In bs, this message translates to:
  /// **'Šta znači Verifikovani partner?'**
  String get whatIsVerifiedPartner;

  /// No description provided for @verifiedPartnerExplanation.
  ///
  /// In bs, this message translates to:
  /// **'Licenca ove klinike je provjerena u registru Veterinarske komore, a njeno osoblje i usluge prikazane ovdje pregledao je VetNow tim.'**
  String get verifiedPartnerExplanation;

  /// No description provided for @gotIt.
  ///
  /// In bs, this message translates to:
  /// **'Razumijem'**
  String get gotIt;

  /// No description provided for @meetTheTeam.
  ///
  /// In bs, this message translates to:
  /// **'Upoznaj tim'**
  String get meetTheTeam;

  /// No description provided for @allServices.
  ///
  /// In bs, this message translates to:
  /// **'Sve usluge'**
  String get allServices;

  /// No description provided for @reviews.
  ///
  /// In bs, this message translates to:
  /// **'Recenzije'**
  String get reviews;

  /// No description provided for @openNow.
  ///
  /// In bs, this message translates to:
  /// **'Otvoreno sada'**
  String get openNow;

  /// No description provided for @language.
  ///
  /// In bs, this message translates to:
  /// **'Jezik'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In bs, this message translates to:
  /// **'Izgled'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In bs, this message translates to:
  /// **'Kao na uređaju'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In bs, this message translates to:
  /// **'Svijetla'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In bs, this message translates to:
  /// **'Tamna'**
  String get themeDark;

  /// No description provided for @chooseTheme.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi izgled'**
  String get chooseTheme;

  /// No description provided for @chooseLanguage.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi jezik'**
  String get chooseLanguage;

  /// No description provided for @bosnian.
  ///
  /// In bs, this message translates to:
  /// **'Bosanski'**
  String get bosnian;

  /// No description provided for @croatian.
  ///
  /// In bs, this message translates to:
  /// **'Hrvatski'**
  String get croatian;

  /// No description provided for @serbian.
  ///
  /// In bs, this message translates to:
  /// **'Srpski'**
  String get serbian;

  /// No description provided for @savePet.
  ///
  /// In bs, this message translates to:
  /// **'Sačuvaj ljubimca'**
  String get savePet;

  /// No description provided for @saveChanges.
  ///
  /// In bs, this message translates to:
  /// **'Sačuvaj izmjene'**
  String get saveChanges;

  /// No description provided for @editPet.
  ///
  /// In bs, this message translates to:
  /// **'Uredi ljubimca'**
  String get editPet;

  /// No description provided for @favourites.
  ///
  /// In bs, this message translates to:
  /// **'Omiljeni'**
  String get favourites;

  /// No description provided for @addToFavourites.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj u omiljene'**
  String get addToFavourites;

  /// No description provided for @removeFromFavourites.
  ///
  /// In bs, this message translates to:
  /// **'Ukloni iz omiljenih'**
  String get removeFromFavourites;

  /// No description provided for @mostVisited.
  ///
  /// In bs, this message translates to:
  /// **'Najčešće dolazi'**
  String get mostVisited;

  /// No description provided for @visits.
  ///
  /// In bs, this message translates to:
  /// **'termina'**
  String get visits;

  /// No description provided for @markFavourite.
  ///
  /// In bs, this message translates to:
  /// **'Označi kao omiljenog'**
  String get markFavourite;

  /// No description provided for @unmarkFavourite.
  ///
  /// In bs, this message translates to:
  /// **'Ukloni iz omiljenih'**
  String get unmarkFavourite;

  /// No description provided for @petsDashboardSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Tvoji ljubimci, na jednom mjestu'**
  String get petsDashboardSubtitle;

  /// No description provided for @viewList.
  ///
  /// In bs, this message translates to:
  /// **'Lista'**
  String get viewList;

  /// No description provided for @viewDashboard.
  ///
  /// In bs, this message translates to:
  /// **'Dashboard'**
  String get viewDashboard;

  /// No description provided for @searchPetsHint.
  ///
  /// In bs, this message translates to:
  /// **'Pretraži po imenu…'**
  String get searchPetsHint;

  /// No description provided for @filterAllSpecies.
  ///
  /// In bs, this message translates to:
  /// **'Sve vrste'**
  String get filterAllSpecies;

  /// No description provided for @noPetsMatchFilter.
  ///
  /// In bs, this message translates to:
  /// **'Nijedan ljubimac ne odgovara pretrazi.'**
  String get noPetsMatchFilter;

  /// No description provided for @dragWholeCardHint.
  ///
  /// In bs, this message translates to:
  /// **'Drži karticu i prevuci da promijeniš redoslijed.'**
  String get dragWholeCardHint;

  /// No description provided for @chooseSpecies.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi vrstu'**
  String get chooseSpecies;

  /// No description provided for @searchSpeciesHint.
  ///
  /// In bs, this message translates to:
  /// **'Pretraži vrste…'**
  String get searchSpeciesHint;

  /// No description provided for @noSpeciesFound.
  ///
  /// In bs, this message translates to:
  /// **'Nema pronađenih vrsta.'**
  String get noSpeciesFound;

  /// No description provided for @approxAge.
  ///
  /// In bs, this message translates to:
  /// **'Star/a otprilike {age}'**
  String approxAge(String age);

  /// No description provided for @selectBirthDate.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi datum'**
  String get selectBirthDate;

  /// No description provided for @tellUsAboutFriend.
  ///
  /// In bs, this message translates to:
  /// **'Reci nam o svom prijatelju'**
  String get tellUsAboutFriend;

  /// No description provided for @weightOptional.
  ///
  /// In bs, this message translates to:
  /// **'Težina (kg) — opcionalno'**
  String get weightOptional;

  /// No description provided for @breed.
  ///
  /// In bs, this message translates to:
  /// **'Rasa'**
  String get breed;

  /// No description provided for @species.
  ///
  /// In bs, this message translates to:
  /// **'Vrsta'**
  String get species;

  /// No description provided for @petName.
  ///
  /// In bs, this message translates to:
  /// **'Ime'**
  String get petName;

  /// No description provided for @petInfoNote.
  ///
  /// In bs, this message translates to:
  /// **'Vakcinacije i druge detalje možeš dodati kasnije sa profila ljubimca.'**
  String get petInfoNote;

  /// No description provided for @deletePet.
  ///
  /// In bs, this message translates to:
  /// **'Ukloni ljubimca'**
  String get deletePet;

  /// No description provided for @deletePetConfirmTitle.
  ///
  /// In bs, this message translates to:
  /// **'Ukloniti {name}?'**
  String deletePetConfirmTitle(String name);

  /// No description provided for @deletePetConfirmMessage.
  ///
  /// In bs, this message translates to:
  /// **'Ovo se ne može poništiti.'**
  String get deletePetConfirmMessage;

  /// No description provided for @deletePetAction.
  ///
  /// In bs, this message translates to:
  /// **'Ukloni'**
  String get deletePetAction;

  /// No description provided for @details.
  ///
  /// In bs, this message translates to:
  /// **'Detalji'**
  String get details;

  /// No description provided for @vaccinationHistory.
  ///
  /// In bs, this message translates to:
  /// **'Historija vakcinacije'**
  String get vaccinationHistory;

  /// No description provided for @noVaccinationRecords.
  ///
  /// In bs, this message translates to:
  /// **'Još nema zapisa o vakcinaciji.\nTvoja veterinarska stanica ih može dodati poslije posjete.'**
  String get noVaccinationRecords;

  /// No description provided for @weight.
  ///
  /// In bs, this message translates to:
  /// **'Težina'**
  String get weight;

  /// No description provided for @microchip.
  ///
  /// In bs, this message translates to:
  /// **'Mikročip'**
  String get microchip;

  /// No description provided for @age.
  ///
  /// In bs, this message translates to:
  /// **'Starost'**
  String get age;

  /// No description provided for @sectionAppointment.
  ///
  /// In bs, this message translates to:
  /// **'Termin'**
  String get sectionAppointment;

  /// No description provided for @appointmentDetails.
  ///
  /// In bs, this message translates to:
  /// **'Detalji termina'**
  String get appointmentDetails;

  /// No description provided for @sectionSpecialist.
  ///
  /// In bs, this message translates to:
  /// **'Specijalista'**
  String get sectionSpecialist;

  /// No description provided for @sectionClinic.
  ///
  /// In bs, this message translates to:
  /// **'Klinika'**
  String get sectionClinic;

  /// No description provided for @labelService.
  ///
  /// In bs, this message translates to:
  /// **'Usluga'**
  String get labelService;

  /// No description provided for @labelDetails.
  ///
  /// In bs, this message translates to:
  /// **'Detalji'**
  String get labelDetails;

  /// No description provided for @labelDuration.
  ///
  /// In bs, this message translates to:
  /// **'Trajanje'**
  String get labelDuration;

  /// No description provided for @labelPet.
  ///
  /// In bs, this message translates to:
  /// **'Ljubimac'**
  String get labelPet;

  /// No description provided for @labelPrice.
  ///
  /// In bs, this message translates to:
  /// **'Cijena'**
  String get labelPrice;

  /// No description provided for @labelName.
  ///
  /// In bs, this message translates to:
  /// **'Naziv'**
  String get labelName;

  /// No description provided for @labelAddress.
  ///
  /// In bs, this message translates to:
  /// **'Adresa'**
  String get labelAddress;

  /// No description provided for @labelPhone.
  ///
  /// In bs, this message translates to:
  /// **'Telefon'**
  String get labelPhone;

  /// No description provided for @servicesWithSpecialist.
  ///
  /// In bs, this message translates to:
  /// **'Usluge kod ovog specijaliste'**
  String get servicesWithSpecialist;

  /// No description provided for @noServicesListed.
  ///
  /// In bs, this message translates to:
  /// **'Još nema navedenih usluga.'**
  String get noServicesListed;

  /// No description provided for @amenityInOffice.
  ///
  /// In bs, this message translates to:
  /// **'Pregledi u ordinaciji'**
  String get amenityInOffice;

  /// No description provided for @amenityInOfficeDesc.
  ///
  /// In bs, this message translates to:
  /// **'Ova klinika prima ljubimce direktno u svojoj ordinaciji.'**
  String get amenityInOfficeDesc;

  /// No description provided for @amenityOnField.
  ///
  /// In bs, this message translates to:
  /// **'Terenske posjete'**
  String get amenityOnField;

  /// No description provided for @amenityOnFieldDesc.
  ///
  /// In bs, this message translates to:
  /// **'Veterinar može doći na vašu kućnu adresu.'**
  String get amenityOnFieldDesc;

  /// No description provided for @amenityParking.
  ///
  /// In bs, this message translates to:
  /// **'Parking'**
  String get amenityParking;

  /// No description provided for @amenityParkingDesc.
  ///
  /// In bs, this message translates to:
  /// **'Besplatan parking dostupan za posjetioce.'**
  String get amenityParkingDesc;

  /// No description provided for @amenityWheelchair.
  ///
  /// In bs, this message translates to:
  /// **'Pristup za invalidska kolica'**
  String get amenityWheelchair;

  /// No description provided for @amenityWheelchairDesc.
  ///
  /// In bs, this message translates to:
  /// **'Objekat je prilagođen osobama sa invaliditetom.'**
  String get amenityWheelchairDesc;

  /// No description provided for @amenityWifi.
  ///
  /// In bs, this message translates to:
  /// **'Besplatan WiFi'**
  String get amenityWifi;

  /// No description provided for @amenityWifiDesc.
  ///
  /// In bs, this message translates to:
  /// **'Besplatan bežični internet dostupan u čekaonici.'**
  String get amenityWifiDesc;

  /// No description provided for @filterClinics.
  ///
  /// In bs, this message translates to:
  /// **'Filtriraj klinike'**
  String get filterClinics;

  /// No description provided for @applyFilters.
  ///
  /// In bs, this message translates to:
  /// **'Primijeni'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In bs, this message translates to:
  /// **'Poništi'**
  String get resetFilters;

  /// No description provided for @trustNoAccount.
  ///
  /// In bs, this message translates to:
  /// **'Bez računa za gledanje'**
  String get trustNoAccount;

  /// No description provided for @trustFewTaps.
  ///
  /// In bs, this message translates to:
  /// **'Rezervacija za par klika'**
  String get trustFewTaps;

  /// No description provided for @roleVeterinarian.
  ///
  /// In bs, this message translates to:
  /// **'Veterinar'**
  String get roleVeterinarian;

  /// No description provided for @roleNurse.
  ///
  /// In bs, this message translates to:
  /// **'Medicinska sestra'**
  String get roleNurse;

  /// No description provided for @roleGroomer.
  ///
  /// In bs, this message translates to:
  /// **'Njegovatelj/ica'**
  String get roleGroomer;

  /// No description provided for @roleNoPreference.
  ///
  /// In bs, this message translates to:
  /// **'Bez preferencije'**
  String get roleNoPreference;

  /// No description provided for @serviceVaccinationName.
  ///
  /// In bs, this message translates to:
  /// **'Vakcinacija'**
  String get serviceVaccinationName;

  /// No description provided for @serviceVaccinationDesc.
  ///
  /// In bs, this message translates to:
  /// **'Osnovne vakcine i vakcina protiv bjesnila'**
  String get serviceVaccinationDesc;

  /// No description provided for @serviceCheckupName.
  ///
  /// In bs, this message translates to:
  /// **'Opći pregled'**
  String get serviceCheckupName;

  /// No description provided for @serviceCheckupDesc.
  ///
  /// In bs, this message translates to:
  /// **'Kompletan fizički pregled'**
  String get serviceCheckupDesc;

  /// No description provided for @serviceDentalName.
  ///
  /// In bs, this message translates to:
  /// **'Čišćenje zuba'**
  String get serviceDentalName;

  /// No description provided for @serviceDentalDesc.
  ///
  /// In bs, this message translates to:
  /// **'Skidanje kamenca i poliranje'**
  String get serviceDentalDesc;

  /// No description provided for @serviceGroomingName.
  ///
  /// In bs, this message translates to:
  /// **'Šišanje i njega'**
  String get serviceGroomingName;

  /// No description provided for @serviceGroomingDesc.
  ///
  /// In bs, this message translates to:
  /// **'Pranje, šišanje i njega noktiju'**
  String get serviceGroomingDesc;

  /// No description provided for @currentAppointment.
  ///
  /// In bs, this message translates to:
  /// **'Trenutni termin'**
  String get currentAppointment;

  /// No description provided for @noFreeSlotsThatDay.
  ///
  /// In bs, this message translates to:
  /// **'Nema slobodnih termina za taj dan. Probaj drugi datum.'**
  String get noFreeSlotsThatDay;

  /// No description provided for @confirmReschedule.
  ///
  /// In bs, this message translates to:
  /// **'Potvrdi novi termin'**
  String get confirmReschedule;

  /// No description provided for @rescheduleSuccess.
  ///
  /// In bs, this message translates to:
  /// **'Termin je pomjeren.'**
  String get rescheduleSuccess;

  /// No description provided for @editProfile.
  ///
  /// In bs, this message translates to:
  /// **'Uredi profil'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In bs, this message translates to:
  /// **'Ažuriraj svoje podatke i lozinku'**
  String get editProfileSubtitle;

  /// No description provided for @profileUpdated.
  ///
  /// In bs, this message translates to:
  /// **'Profil je ažuriran.'**
  String get profileUpdated;

  /// No description provided for @sectionPersonalInfo.
  ///
  /// In bs, this message translates to:
  /// **'Lični podaci'**
  String get sectionPersonalInfo;

  /// No description provided for @sectionContact.
  ///
  /// In bs, this message translates to:
  /// **'Kontakt'**
  String get sectionContact;

  /// No description provided for @sectionLocation.
  ///
  /// In bs, this message translates to:
  /// **'Lokacija'**
  String get sectionLocation;

  /// No description provided for @sectionSecurity.
  ///
  /// In bs, this message translates to:
  /// **'Sigurnost'**
  String get sectionSecurity;

  /// No description provided for @labelCity.
  ///
  /// In bs, this message translates to:
  /// **'Grad'**
  String get labelCity;

  /// No description provided for @labelCountry.
  ///
  /// In bs, this message translates to:
  /// **'Država'**
  String get labelCountry;

  /// No description provided for @newPassword.
  ///
  /// In bs, this message translates to:
  /// **'Nova lozinka'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In bs, this message translates to:
  /// **'Ostavi prazno ako je ne mijenjaš'**
  String get newPasswordHint;

  /// No description provided for @couldNotPlaceCall.
  ///
  /// In bs, this message translates to:
  /// **'Poziv nije moguće pokrenuti sa ovog uređaja.'**
  String get couldNotPlaceCall;

  /// No description provided for @verifyAccountTitle.
  ///
  /// In bs, this message translates to:
  /// **'Potvrda naloga'**
  String get verifyAccountTitle;

  /// No description provided for @verifyAccountHeadline.
  ///
  /// In bs, this message translates to:
  /// **'Provjeri svoj email'**
  String get verifyAccountHeadline;

  /// No description provided for @verifyAccountBody.
  ///
  /// In bs, this message translates to:
  /// **'Poslali smo ti kod za potvrdu. Upiši ga ispod da aktiviraš nalog.'**
  String get verifyAccountBody;

  /// No description provided for @verifyAccountBodyFor.
  ///
  /// In bs, this message translates to:
  /// **'Poslali smo kod za potvrdu na {contact}. Upiši ga ispod da aktiviraš nalog.'**
  String verifyAccountBodyFor(String contact);

  /// No description provided for @verifyAccountAction.
  ///
  /// In bs, this message translates to:
  /// **'Potvrdi nalog'**
  String get verifyAccountAction;

  /// No description provided for @verifyAccountResendHint.
  ///
  /// In bs, this message translates to:
  /// **'Nisi dobio kod? Pokušaj se prijaviti ponovo — šaljemo novi kod pri svakoj prijavi.'**
  String get verifyAccountResendHint;

  /// No description provided for @filterAllStaff.
  ///
  /// In bs, this message translates to:
  /// **'Svi'**
  String get filterAllStaff;

  /// No description provided for @a11yLoading.
  ///
  /// In bs, this message translates to:
  /// **'Učitavanje'**
  String get a11yLoading;

  /// No description provided for @a11yBack.
  ///
  /// In bs, this message translates to:
  /// **'Nazad'**
  String get a11yBack;

  /// No description provided for @a11yClearSearch.
  ///
  /// In bs, this message translates to:
  /// **'Obriši pretragu'**
  String get a11yClearSearch;

  /// No description provided for @a11yShowPassword.
  ///
  /// In bs, this message translates to:
  /// **'Prikaži lozinku'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In bs, this message translates to:
  /// **'Sakrij lozinku'**
  String get a11yHidePassword;

  /// No description provided for @a11yRateStars.
  ///
  /// In bs, this message translates to:
  /// **'{count, plural, one{{count} zvjezdica} few{{count} zvjezdice} other{{count} zvjezdica}}'**
  String a11yRateStars(int count);

  /// No description provided for @diagnosticsTitle.
  ///
  /// In bs, this message translates to:
  /// **'Pomoć i dijagnostika'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsAbout.
  ///
  /// In bs, this message translates to:
  /// **'O aplikaciji'**
  String get diagnosticsAbout;

  /// No description provided for @diagnosticsVersion.
  ///
  /// In bs, this message translates to:
  /// **'Verzija'**
  String get diagnosticsVersion;

  /// No description provided for @diagnosticsBackend.
  ///
  /// In bs, this message translates to:
  /// **'Server'**
  String get diagnosticsBackend;

  /// No description provided for @diagnosticsReports.
  ///
  /// In bs, this message translates to:
  /// **'Zapisi o greškama'**
  String get diagnosticsReports;

  /// No description provided for @diagnosticsEmpty.
  ///
  /// In bs, this message translates to:
  /// **'Nema zabilježenih grešaka. To je dobra vijest.'**
  String get diagnosticsEmpty;

  /// No description provided for @diagnosticsExplainer.
  ///
  /// In bs, this message translates to:
  /// **'Ako nešto krene po zlu, aplikacija to zabilježi ovdje — samo na tvom telefonu, ništa se ne šalje. Kopiraj i pošalji nam kad prijavljuješ problem.'**
  String get diagnosticsExplainer;

  /// No description provided for @diagnosticsCopy.
  ///
  /// In bs, this message translates to:
  /// **'Kopiraj izvještaj'**
  String get diagnosticsCopy;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In bs, this message translates to:
  /// **'Kopirano'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsClear.
  ///
  /// In bs, this message translates to:
  /// **'Obriši zapise'**
  String get diagnosticsClear;

  /// No description provided for @diagnosticsCleared.
  ///
  /// In bs, this message translates to:
  /// **'Zapisi obrisani'**
  String get diagnosticsCleared;

  /// No description provided for @diagnosticsFatal.
  ///
  /// In bs, this message translates to:
  /// **'Pad'**
  String get diagnosticsFatal;

  /// No description provided for @diagnosticsHandled.
  ///
  /// In bs, this message translates to:
  /// **'Greška'**
  String get diagnosticsHandled;

  /// No description provided for @configWarningTitle.
  ///
  /// In bs, this message translates to:
  /// **'Ovaj build nije spreman za objavu'**
  String get configWarningTitle;

  /// No description provided for @configWarningBody.
  ///
  /// In bs, this message translates to:
  /// **'Aplikacija je podešena da priča sa serverom koji postoji samo na računaru na kojem je build napravljen, pa ništa neće raditi na telefonu. Ponovo napravi build sa --dart-define=API_BASE_URL=https://…'**
  String get configWarningBody;

  /// No description provided for @reportReview.
  ///
  /// In bs, this message translates to:
  /// **'Prijavi recenziju'**
  String get reportReview;

  /// No description provided for @reportReviewTitle.
  ///
  /// In bs, this message translates to:
  /// **'Prijaviti ovu recenziju?'**
  String get reportReviewTitle;

  /// No description provided for @reportReviewBody.
  ///
  /// In bs, this message translates to:
  /// **'Otvorićemo e-mail s detaljima recenzije da ga pošalješ. Pregledamo svaku prijavu i uklanjamo sadržaj koji krši pravila.'**
  String get reportReviewBody;

  /// No description provided for @reportReviewSend.
  ///
  /// In bs, this message translates to:
  /// **'Otvori e-mail'**
  String get reportReviewSend;

  /// No description provided for @reportReviewFailed.
  ///
  /// In bs, this message translates to:
  /// **'Nismo mogli otvoriti e-mail aplikaciju. Kontakt adresa je kopirana.'**
  String get reportReviewFailed;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In bs, this message translates to:
  /// **'Zaboravljena lozinka'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In bs, this message translates to:
  /// **'Resetovanje lozinke još nije dostupno u aplikaciji. Javi nam se na {email} i vratit ćemo ti pristup.'**
  String forgotPasswordBody(String email);

  /// No description provided for @copyEmail.
  ///
  /// In bs, this message translates to:
  /// **'Kopiraj adresu'**
  String get copyEmail;

  /// No description provided for @copied.
  ///
  /// In bs, this message translates to:
  /// **'Kopirano'**
  String get copied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bs', 'hr', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bs':
      return AppLocalizationsBs();
    case 'hr':
      return AppLocalizationsHr();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
