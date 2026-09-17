import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/vet_service.dart';

/// Central place for the mock services/roles shown across the app
/// (station detail, staff profiles, booking). Keeping them here means
/// every screen shows the same localized name for "Vaccination" etc,
/// with a consistent icon + accent color, instead of each screen
/// hand-rolling its own English string and plain card.
///
/// Real backend integration will replace this with data straight from
/// the Services/Employees endpoints — at that point this becomes a
/// display-formatting helper rather than the source of truth.
class ServiceCatalog {
  ServiceCatalog._();

  static VetService service(BuildContext context, ServiceKind kind) {
    final l10n = AppLocalizations.of(context)!;
    return switch (kind) {
      ServiceKind.vaccination => VetService(name: l10n.serviceVaccinationName, description: l10n.serviceVaccinationDesc, priceKm: 25, durationMinutes: 20, kind: kind),
      ServiceKind.checkup => VetService(name: l10n.serviceCheckupName, description: l10n.serviceCheckupDesc, priceKm: 30, durationMinutes: 30, kind: kind),
      ServiceKind.dental => VetService(name: l10n.serviceDentalName, description: l10n.serviceDentalDesc, priceKm: 60, durationMinutes: 40, kind: kind),
      ServiceKind.grooming => VetService(name: l10n.serviceGroomingName, description: l10n.serviceGroomingDesc, priceKm: 40, durationMinutes: 45, kind: kind),
    };
  }

  static IconData icon(ServiceKind? kind) => switch (kind) {
        ServiceKind.vaccination => Icons.vaccines_rounded,
        ServiceKind.checkup => Icons.monitor_heart_outlined,
        ServiceKind.dental => Icons.clean_hands_outlined,
        ServiceKind.grooming => Icons.content_cut_rounded,
        null => Icons.medical_services_outlined,
      };

  static Color color(ServiceKind? kind) => switch (kind) {
        ServiceKind.vaccination => AppColors.primary,
        ServiceKind.checkup => AppColors.info,
        ServiceKind.dental => AppColors.gold,
        ServiceKind.grooming => AppColors.accent,
        null => AppColors.primary,
      };

  static String roleVeterinarian(BuildContext context) => AppLocalizations.of(context)!.roleVeterinarian;
  static String roleNurse(BuildContext context) => AppLocalizations.of(context)!.roleNurse;
  static String roleGroomer(BuildContext context) => AppLocalizations.of(context)!.roleGroomer;
  static String roleNoPreference(BuildContext context) => AppLocalizations.of(context)!.roleNoPreference;
}
