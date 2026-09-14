import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/vet_station.dart';
import '../services/api_client.dart';
import '../services/vet_station_api_service.dart';
import '../widgets/rating_badge.dart';
import '../widgets/verified_badge.dart';
import '../widgets/hover_card.dart';
import '../widgets/app_button.dart';
import '../widgets/language_picker.dart';
import '../widgets/paw_loader.dart';
import '../widgets/vet_hero_background.dart';
import 'vet_station_detail_screen.dart';

/// The app's real front door — no login required. Mirrors the
/// rezervacija.app pattern: pick a city, search, filter, browse partner
/// vet stations, then only ask for an account once someone books.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

/// Every one of these sorts on a value the backend actually computes.
/// "Nearest" used to sit here too, sorting by a distance the server never
/// sends — so it reordered nothing while looking like it did.
enum _SortFilter { recommended, topRated, mostReviewed }

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  /// `null` means "all cities". The picker used to default to a hard-coded
  /// "Sarajevo", which — now that the backend actually returns a city — would
  /// have silently hidden every clinic outside it on first open.
  String? _selectedCity;
  _SortFilter _activeFilter = _SortFilter.recommended;

  bool _amenityParking = false;
  bool _amenityWifi = false;
  bool _amenityWheelchair = false;
  bool _amenityInOffice = false;
  bool _amenityOnField = false;

  bool get _hasActiveAmenityFilters =>
      _amenityParking || _amenityWifi || _amenityWheelchair || _amenityInOffice || _amenityOnField;

  /// Built from what the API actually returned, so the list can never offer a
  /// city with no clinics in it — or omit one that has them.
  List<String> get _cities {
    final seen = _stations
        .map((s) => s.city.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return seen;
  }

  List<VetStation> _stations = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final result = await VetStationApiService.search();
      if (!mounted) return;
      setState(() {
        _stations = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'network';
      });
    }
  }

  List<VetStation> get _filtered {
    // A null selection means "all cities". A station with no city recorded is
    // kept either way rather than being filtered into invisibility.
    final city = _selectedCity;
    var list = city == null
        ? List<VetStation>.from(_stations)
        : _stations.where((s) => s.city.isEmpty || s.city == city).toList();
    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.trim().toLowerCase();
      list = list.where((s) => s.name.toLowerCase().contains(q)).toList();
    }
    if (_amenityParking) list = list.where((s) => s.parking).toList();
    if (_amenityWifi) list = list.where((s) => s.wifi).toList();
    if (_amenityWheelchair) list = list.where((s) => s.wheelchair).toList();
    if (_amenityInOffice) list = list.where((s) => s.inOffice).toList();
    if (_amenityOnField) list = list.where((s) => s.onField).toList();
    switch (_activeFilter) {
      case _SortFilter.recommended:
        // Score weighted by how many people stand behind it, so one lone
        // five-star review doesn't outrank a clinic with fifty good ones.
        list.sort((a, b) => (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount));
        break;
      case _SortFilter.topRated:
        // Unrated clinics sort last instead of tying at 0.0 with the worst.
        list.sort((a, b) {
          if (a.hasReviews != b.hasReviews) return a.hasReviews ? -1 : 1;
          return b.rating.compareTo(a.rating);
        });
        break;
      case _SortFilter.mostReviewed:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
    return list;
  }

  void _openCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CityPickerSheet(
        cities: _cities,
        selected: _selectedCity,
        onSelect: (city) {
          setState(() => _selectedCity = city);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openAmenitiesFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => _AmenitiesFilterSheet(
          parking: _amenityParking,
          wifi: _amenityWifi,
          wheelchair: _amenityWheelchair,
          inOffice: _amenityInOffice,
          onField: _amenityOnField,
          onToggle: (key) {
            setSheetState(() {});
            setState(() {
              switch (key) {
                case 'parking':
                  _amenityParking = !_amenityParking;
                  break;
                case 'wifi':
                  _amenityWifi = !_amenityWifi;
                  break;
                case 'wheelchair':
                  _amenityWheelchair = !_amenityWheelchair;
                  break;
                case 'inOffice':
                  _amenityInOffice = !_amenityInOffice;
                  break;
                case 'onField':
                  _amenityOnField = !_amenityOnField;
                  break;
              }
            });
          },
          onReset: () {
            setState(() {
              _amenityParking = false;
              _amenityWifi = false;
              _amenityWheelchair = false;
              _amenityInOffice = false;
              _amenityOnField = false;
            });
            Navigator.of(sheetContext).pop();
          },
          onApply: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stations = _filtered;
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _Hero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.s5,
              AppSpacing.pagePadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: AppShadows.card,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l10n.searchHint,
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                                child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _openCityPicker,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(_selectedCity ?? l10n.allCities,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.text)),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _FilterChip(
                        label: l10n.filterRecommended,
                        icon: Icons.auto_awesome,
                        selected: _activeFilter == _SortFilter.recommended,
                        onTap: () => setState(() => _activeFilter = _SortFilter.recommended),
                      ),
                      _FilterChip(
                        label: l10n.filterTopRated,
                        icon: Icons.star_rounded,
                        selected: _activeFilter == _SortFilter.topRated,
                        onTap: () => setState(() => _activeFilter = _SortFilter.topRated),
                      ),
                      _FilterChip(
                        label: l10n.filterMostReviewed,
                        icon: Icons.reviews_outlined,
                        selected: _activeFilter == _SortFilter.mostReviewed,
                        onTap: () => setState(() => _activeFilter = _SortFilter.mostReviewed),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      // With no city selected the "… in {city}" phrasing would
                      // read as a lie, so fall back to a plain count.
                      _selectedCity == null
                          ? l10n.clinicsFound(stations.length)
                          : l10n.clinicsInCity(stations.length, _selectedCity!),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
                    ),
                    InkWell(
                      onTap: _openAmenitiesFilterSheet,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _hasActiveAmenityFilters ? AppColors.primary50 : AppColors.bgMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.tune,
                                size: 16, color: _hasActiveAmenityFilters ? AppColors.primary : AppColors.textMuted),
                          ),
                          if (_hasActiveAmenityFilters)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                height: 9,
                                width: 9,
                                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverToBoxAdapter(child: _LoadingState())
        else if (_loadError != null)
          SliverToBoxAdapter(child: _ErrorState(onRetry: _loadStations))
        else if (stations.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              0,
              AppSpacing.pagePadding,
              110,
            ),
            sliver: SliverList.separated(
              itemCount: stations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
              itemBuilder: (context, index) {
                final station = stations[index];
                return _StationCard(
                  station: station,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VetStationDetailScreen(station: station)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Premium hero: deep-ink gradient, brand mark, city selector.
/// This is the "serious but sweet" moment — confident dark surface,
/// a paw mark, and a friendly one-liner underneath.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppGradients.ink,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl2),
          bottomRight: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: VetHeroBackground()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.s5,
              AppSpacing.pagePadding,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pets, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'VetNow',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => showLanguagePicker(context),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.translate_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 17),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  AppLocalizations.of(context)!.exploreHeroTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  AppLocalizations.of(context)!.exploreHeroSubtitle,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75), height: 1.4),
                ),
                const SizedBox(height: AppSpacing.s5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrustPill(icon: Icons.verified_rounded, label: AppLocalizations.of(context)!.trustNoAccount),
                    _TrustPill(icon: Icons.bolt_rounded, label: AppLocalizations.of(context)!.trustFewTaps),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]) : null,
            color: selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: selected ? Colors.transparent : AppColors.border),
            boxShadow: selected ? AppShadows.glow(AppColors.ink) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final VetStation station;
  final VoidCallback onTap;

  const _StationCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: onTap,
      child: DecoratedBox(
        // Shadow lives outside the ClipRRect — clipping it would cut the
        // blur off at the card edge and leave the list looking flat.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 104,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryLight, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Same top-left light as every other branded surface,
                        // so the thumbnail is lit rather than flat-filled.
                        const Positioned.fill(
                          child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
                        ),
                        Center(
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                            ),
                            child: const Icon(Icons.pets, color: Colors.white, size: 21),
                          ),
                        ),
                        if (!station.openNow)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              color: Colors.black54,
                              child: const Text('Closed',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  station.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.text),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (station.verifiedPartner) ...[
                            const VerifiedBadge(compact: true),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            children: [
                              RatingBadge(
                                rating: station.rating,
                                reviewCount: station.reviewCount,
                                dense: true,
                                emptyLabel: AppLocalizations.of(context)!.noRatingsYet,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 2),
                              // The real street and city, now that the search
                              // endpoint returns them. This slot used to show
                              // "0.0 km" for every clinic — the distance it showed
                              // had no source and was always zero.
                              Expanded(
                                child: Text(
                                  station.locationLine,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              if (station.parking) const _MiniTag(icon: Icons.local_parking_outlined),
                              if (station.wifi) const _MiniTag(icon: Icons.wifi),
                              if (station.wheelchair) const _MiniTag(icon: Icons.accessible_outlined),
                              if (station.onField) const _MiniTag(icon: Icons.home_work_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  const _MiniTag({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.bgMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 12, color: AppColors.textSecondary),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
      child: Center(child: PawLoader(size: 32, color: AppColors.primary)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.pagePadding),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(l10n.networkError, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: l10n.retry,
            icon: Icons.refresh,
            fullWidth: false,
            variant: AppButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.pagePadding),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
            child: const Icon(Icons.search_off, size: 28, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            AppLocalizations.of(context)!.noClinicsMatch,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CityPickerSheet extends StatelessWidget {
  final List<String> cities;

  /// `null` is a real choice here, not "nothing picked": it means every city.
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CityPickerSheet({
    required this.cities,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s3, AppSpacing.s6, AppSpacing.s8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl2),
          topRight: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: AppSpacing.s5),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.chooseCity,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          // "All cities" leads the list so there is always a way back out of a
          // filter — and so the sheet is never empty when the API returns
          // clinics with no city recorded.
          ...<String?>[null, ...cities].map((c) {
            final isSelected = c == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: InkWell(
                onTap: () => onSelect(c),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]) : null,
                    color: isSelected ? null : AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.15) : AppColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          c == null ? Icons.public_rounded : Icons.location_city_rounded,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          c ?? AppLocalizations.of(context)!.allCities,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.text,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20)
                      else
                        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AmenitiesFilterSheet extends StatelessWidget {
  final bool parking;
  final bool wifi;
  final bool wheelchair;
  final bool inOffice;
  final bool onField;
  final ValueChanged<String> onToggle;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const _AmenitiesFilterSheet({
    required this.parking,
    required this.wifi,
    required this.wheelchair,
    required this.inOffice,
    required this.onField,
    required this.onToggle,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <(String key, IconData icon, String label, bool value)>[
      ('inOffice', Icons.local_hospital_outlined, l10n.amenityInOffice, inOffice),
      ('onField', Icons.home_work_outlined, l10n.amenityOnField, onField),
      ('parking', Icons.local_parking_outlined, l10n.amenityParking, parking),
      ('wheelchair', Icons.accessible_outlined, l10n.amenityWheelchair, wheelchair),
      ('wifi', Icons.wifi, l10n.amenityWifi, wifi),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s3, AppSpacing.s6, AppSpacing.s8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(AppRadius.xl2), topRight: Radius.circular(AppRadius.xl2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: AppSpacing.s5),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filterClinics,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.text)),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          ...options.map((opt) {
            final selected = opt.$4;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: InkWell(
                onTap: () => onToggle(opt.$1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary50 : AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: selected ? AppColors.primary : AppColors.borderLight, width: selected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.bgMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(opt.$2, size: 17, color: selected ? Colors.white : AppColors.textSecondary),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(opt.$3,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ),
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.radio_button_off,
                        color: selected ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text(l10n.resetFilters,
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: AppButton(label: l10n.applyFilters, onPressed: onApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
