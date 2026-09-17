import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/profile_settings_api_service.dart';
import '../services/profile_validation.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/paw_loader.dart';

/// Edit the signed-in person's account details.
///
/// Backed by GET/PUT /api/ProfileSettings — both already existed on the
/// backend but nothing in the app used them, so a person could see their
/// profile but never change it.
///
/// Password is optional here: leaving it blank keeps the current one, and
/// only a typed value is sent. Username is not editable — the backend
/// requires it on every save as the identifying field, so it is carried
/// through unchanged from the session.
///
/// Pops `true` when something was saved, so the profile screen can reload.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  /// Everything currently wrong with the form, by field. Empty when
  /// the form is good.
  Map<ProfileField, String> _errors = {};

  /// So a failed save can put the cursor in the first field it
  /// objects to, rather than leaving someone to hunt for the red one.
  final _focus = {
    for (final field in ProfileField.values) field: FocusNode(),
  };

  /// So the same field can be scrolled into view. A FocusNode alone
  /// moves the caret but not the page, and on a form this long the
  /// field in question is usually off screen.
  final _anchors = {
    for (final field in ProfileField.values) field: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _city, _country, _address, _password]) {
      c.dispose();
    }
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (auth.token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final settings = await ProfileSettingsApiService.get(auth.token!);
      if (!mounted) return;
      setState(() {
        _firstName.text = settings.firstName ?? '';
        _lastName.text = settings.lastName ?? '';
        _phone.text = settings.phone ?? '';
        _email.text = settings.email ?? '';
        _city.text = settings.city ?? '';
        _country.text = settings.country ?? '';
        _address.text = settings.address ?? '';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = AppLocalizations.of(context)!.networkError;
        _loading = false;
      });
    }
  }

  /// Clears one field's complaint as soon as it is being fixed.
  ///
  /// Leaving a field red while someone is actively typing into it is
  /// the app arguing with them about something they are already
  /// dealing with.
  void _clearError(ProfileField field) {
    if (!_errors.containsKey(field)) return;
    setState(() => _errors = {..._errors}..remove(field));
  }

  /// Puts the first rejected field on screen and in focus.
  ///
  /// Order matters: ProfileField.values runs top to bottom down the
  /// form, so "first" means the one nearest the top, not whichever
  /// the map happened to yield first.
  void _goToFirstError() {
    final field =
        ProfileField.values.firstWhere(_errors.containsKey, orElse: () => ProfileField.firstName);
    final anchor = _anchors[field]?.currentContext;
    if (anchor == null) return;

    Scrollable.ensureVisible(
      anchor,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      // Not flush against the top edge — a field pinned to the very
      // top of the viewport reads as cut off, and its label sits
      // under the app bar.
      alignment: 0.15,
    );
    _focus[field]?.requestFocus();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);

    // The backend wants the username on every save as the identifying
    // field, and it is carried through from the session rather than
    // being editable. If it is somehow missing, this used to `return`
    // — the button stopped spinning, nothing was sent, and nothing
    // was said. A save that silently does nothing is worse than one
    // that fails.
    if (auth.token == null || auth.username == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.sessionExpired)));
      return;
    }

    // Checked here rather than left to the backend. Its refusal comes
    // back as an English sentence with no idea which field caused it,
    // which in an app that speaks Bosnian, Croatian and Serbian is
    // not an error message so much as a dead end.
    final problems = validateProfile(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      l10n: l10n,
    );

    if (problems.isNotEmpty) {
      setState(() => _errors = problems);
      _goToFirstError();

      // Only when there is more than one. With a single error the
      // field it just scrolled to says everything, and a message
      // repeating it is noise.
      if (problems.length > 1) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.validationCheckFields(problems.length)),
          ));
      }
      return;
    }

    setState(() {
      _errors = {};
      _saving = true;
    });
    try {
      await ProfileSettingsApiService.edit(
        token: auth.token!,
        username: auth.username!,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        address: _address.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
      );

      // Keep the session's displayed name in step with what was just saved,
      // so the profile header doesn't show the old name until next login.
      final newName = '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
      if (newName.isNotEmpty) auth.updateDisplayName(newName, email: _email.text.trim());

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.networkError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.editProfile),
      body: _loading
          ? const Center(child: PawLoader(size: 34))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 38, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.s5,
                    AppSpacing.pagePadding,
                    AppSpacing.s10,
                  ),
                  children: [
                    Text(
                      l10n.editProfileSubtitle,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    _FormSection(
                      title: l10n.sectionPersonalInfo,
                      icon: Icons.badge_outlined,
                      children: [
                        AppTextField(
                          key: _anchors[ProfileField.firstName],
                          label: l10n.firstName,
                          controller: _firstName,
                          focusNode: _focus[ProfileField.firstName],
                          prefixIcon: Icons.person_outline,
                          isError: _errors.containsKey(ProfileField.firstName),
                          errorText: _errors[ProfileField.firstName],
                          onChanged: (_) => _clearError(ProfileField.firstName),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(
                          key: _anchors[ProfileField.lastName],
                          label: l10n.lastName,
                          controller: _lastName,
                          focusNode: _focus[ProfileField.lastName],
                          prefixIcon: Icons.person_outline,
                          isError: _errors.containsKey(ProfileField.lastName),
                          errorText: _errors[ProfileField.lastName],
                          onChanged: (_) => _clearError(ProfileField.lastName),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _FormSection(
                      title: l10n.sectionContact,
                      icon: Icons.alternate_email_rounded,
                      children: [
                        AppTextField(
                          key: _anchors[ProfileField.email],
                          label: l10n.email,
                          controller: _email,
                          focusNode: _focus[ProfileField.email],
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          isError: _errors.containsKey(ProfileField.email),
                          errorText: _errors[ProfileField.email],
                          onChanged: (_) => _clearError(ProfileField.email),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(
                          key: _anchors[ProfileField.phone],
                          label: l10n.labelPhone,
                          controller: _phone,
                          focusNode: _focus[ProfileField.phone],
                          prefixIcon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          isError: _errors.containsKey(ProfileField.phone),
                          errorText: _errors[ProfileField.phone],
                          onChanged: (_) => _clearError(ProfileField.phone),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _FormSection(
                      title: l10n.sectionLocation,
                      icon: Icons.place_outlined,
                      children: [
                        AppTextField(label: l10n.labelAddress, controller: _address, prefixIcon: Icons.home_outlined),
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(label: l10n.labelCity, controller: _city, prefixIcon: Icons.location_city_outlined),
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(label: l10n.labelCountry, controller: _country, prefixIcon: Icons.public_outlined),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _FormSection(
                      title: l10n.sectionSecurity,
                      icon: Icons.lock_outline_rounded,
                      children: [
                        AppTextField(
                          key: _anchors[ProfileField.password],
                          label: l10n.newPassword,
                          controller: _password,
                          focusNode: _focus[ProfileField.password],
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isError: _errors.containsKey(ProfileField.password),
                          errorText: _errors[ProfileField.password],
                          onChanged: (_) => _clearError(ProfileField.password),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          l10n.newPasswordHint,
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    AppButton(
                      label: l10n.saveChanges,
                      icon: Icons.check_rounded,
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
    );
  }
}

/// Grouped card of related fields — matches the sectioned look used on
/// the appointment detail screen so forms feel part of the same app.
class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.s3),
              // Section titles here are phrases — "Lozinka i sigurnost" —
              // beside a fixed-width icon tile.
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          ...children,
        ],
      ),
    );
  }
}
