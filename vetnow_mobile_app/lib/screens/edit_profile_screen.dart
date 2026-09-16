import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/profile_settings_api_service.dart';
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);
    if (auth.token == null || auth.username == null) return;

    setState(() => _saving = true);
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
                        AppTextField(label: l10n.firstName, controller: _firstName, prefixIcon: Icons.person_outline),
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(label: l10n.lastName, controller: _lastName, prefixIcon: Icons.person_outline),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _FormSection(
                      title: l10n.sectionContact,
                      icon: Icons.alternate_email_rounded,
                      children: [
                        AppTextField(
                          label: l10n.email,
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(
                          label: l10n.labelPhone,
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.call_outlined,
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
                          label: l10n.newPassword,
                          controller: _password,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
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
