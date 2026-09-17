import 'package:flutter/material.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_button.dart';
import '../widgets/hero_shell.dart';
import '../widgets/vet_hero_background.dart';

/// Three cards, once, the first time the app is opened.
///
/// The app opened straight onto Explore with no word about what it is.
/// Somebody who installed it on a recommendation arrived at a list of
/// clinics and had to work out the rest from the icons — and the one
/// thing that actually distinguishes VetNow, that you can browse and
/// book without an account, was the thing least visible.
///
/// Three, and no more. A fourth card is where an introduction stops
/// being an introduction and starts being something to get past, and
/// Skip is on screen from the first frame for exactly that reason: this
/// is an offer, not a toll gate.
class OnboardingScreen extends StatefulWidget {
  /// Called when the person is done, whether they read it or skipped it.
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next(int last) {
    Haptics.select();
    if (_index >= last) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cards = <(IconData, String, String)>[
      (Icons.search_rounded, l10n.onboarding1Title, l10n.onboarding1Body),
      (Icons.event_available_rounded, l10n.onboarding2Title, l10n.onboarding2Body),
      (Icons.pets_rounded, l10n.onboarding3Title, l10n.onboarding3Body),
    ];
    final last = cards.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The same layered ink the sign-in prompt and every header
          // use, so the first screen anybody sees already looks like the
          // app rather than like a slideshow bolted onto the front.
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.ink),
            child: VetHeroBackground(),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.inkSheen),
            ),
          ),
          const HeroVignette(),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    child: TextButton(
                      onPressed: () {
                        Haptics.select();
                        widget.onDone();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.8),
                      ),
                      child: Text(
                        l10n.onboardingSkip,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: cards.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final (icon, title, body) = cards[i];
                      return _Card(icon: icon, title: title, body: body);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        // The current one is a bar rather than a bigger
                        // dot: at six pixels a size difference is a
                        // guess, a shape difference is not.
                        width: i == _index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.s6,
                      AppSpacing.pagePadding,
                      AppSpacing.s6),
                  child: AppButton(
                    label: _index >= last ? l10n.onboardingStart : l10n.onboardingNext,
                    icon: _index >= last
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                    onPressed: () => _next(last),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Card({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 96,
            width: 96,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primaryDark]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 27,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
