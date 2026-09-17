import '../l10n/app_localizations.dart';

/// Which field a validation message belongs to.
enum ProfileField { firstName, lastName, email, phone, password }

/// Checks the edit-profile form before anything is sent.
///
/// Deliberately a plain function rather than a pile of `validator:`
/// callbacks on a Form. Three reasons:
///
///  * It returns *every* problem at once. A Form that stops at the first
///    failure makes someone fix one field, press save, and discover the
///    next one — four times over.
///  * It can be tested without building a widget, so the rules are
///    covered by fast unit tests rather than by pumping a screen.
///  * The screen decides what to do with the result: paint the fields,
///    scroll to the first one, and say how many are left. The rules
///    themselves stay out of the layout.
///
/// Until now there was no client-side checking at all. The backend's own
/// refusal came back as an English sentence in a grey snackbar at the
/// bottom of the screen — in an app that speaks three languages, none of
/// them English, with no indication of which field was wrong.
///
/// An empty map means the form is good.
Map<ProfileField, String> validateProfile({
  required String firstName,
  required String lastName,
  required String email,
  required String phone,
  required String password,
  required AppLocalizations l10n,
}) {
  final errors = <ProfileField, String>{};

  final first = firstName.trim();
  if (first.isEmpty) {
    errors[ProfileField.firstName] = l10n.validationFirstNameRequired;
  } else if (first.length < 2) {
    errors[ProfileField.firstName] = l10n.validationNameTooShort;
  }

  final last = lastName.trim();
  if (last.isEmpty) {
    errors[ProfileField.lastName] = l10n.validationLastNameRequired;
  } else if (last.length < 2) {
    errors[ProfileField.lastName] = l10n.validationNameTooShort;
  }

  final mail = email.trim();
  if (mail.isEmpty) {
    errors[ProfileField.email] = l10n.validationEmailRequired;
  } else if (!_looksLikeEmail(mail)) {
    errors[ProfileField.email] = l10n.validationEmailInvalid;
  }

  // Optional — plenty of accounts have no phone on file, and demanding
  // one to change a surname would be absurd. Only a typed value is
  // checked.
  final tel = phone.trim();
  if (tel.isNotEmpty) {
    if (!_looksLikePhone(tel)) {
      errors[ProfileField.phone] = l10n.validationPhoneInvalid;
    } else if (_digitsIn(tel) < 6) {
      errors[ProfileField.phone] = l10n.validationPhoneTooShort;
    }
  }

  // Blank means "keep the current one" — that is the whole contract of
  // this field, so an empty box is not an error.
  if (password.isNotEmpty && password.length < 8) {
    errors[ProfileField.password] = l10n.validationPasswordTooShort;
  }

  return errors;
}

/// Deliberately loose.
///
/// A strict RFC 5322 pattern rejects addresses that work and accepts
/// ones that do not, and the only real test is whether mail arrives.
/// This catches the typo worth catching — a missing @ or a missing dot —
/// and lets the server be the authority on the rest.
bool _looksLikeEmail(String value) {
  if (value.contains(' ')) return false;
  final at = value.indexOf('@');
  if (at <= 0 || at != value.lastIndexOf('@')) return false;

  final domain = value.substring(at + 1);
  if (!domain.contains('.')) return false;
  if (domain.startsWith('.') || domain.endsWith('.')) return false;
  return domain.split('.').every((part) => part.isNotEmpty);
}

/// Digits, spaces, and the punctuation people actually type into a phone
/// number: +387 61 234-567, (033) 123 456.
bool _looksLikePhone(String value) =>
    RegExp(r'^[0-9+()\-/ .]+$').hasMatch(value);

int _digitsIn(String value) => RegExp(r'[0-9]').allMatches(value).length;
