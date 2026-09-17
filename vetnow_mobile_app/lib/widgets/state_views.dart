import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_info.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import 'app_button.dart';

/// What a screen shows when a request failed.
///
/// Every screen but Explore used to handle this by printing a line of
/// grey text and leaving the person stuck: no retry, and nothing to do
/// but back out and come in again. Worse, Appointments passed the error
/// through as its *empty-state* text, so a dropped connection and an
/// empty calendar looked identical.
///
/// The two are not the same thing and must not look the same: one means
/// "you have nothing booked", the other means "we could not ask".
class ErrorStateView extends StatelessWidget {
  final VoidCallback onRetry;

  /// The server's own wording when it sent one. A network failure has no
  /// message worth showing, so that case falls back to the generic line.
  final String? message;

  /// Fills the viewport and stays pull-to-refreshable. Off for a slot
  /// inside an already-scrolling page.
  final bool scrollable;

  const ErrorStateView({
    super.key,
    required this.onRetry,
    this.message,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 'network' is the sentinel the screens use for "no server", which is
    // not a sentence anyone should read.
    final noServer = message == null || message == 'network';

    // A release built without --dart-define=API_BASE_URL talks to the
    // machine it was compiled on, so on a phone *every* request fails and
    // every screen says "check your connection" — which sends people to
    // their router over a mistake in the build command. When we can tell
    // that is what happened, say that instead.
    //
    // Release only: in development, pointing at localhost is correct, and
    // a dev server that is simply not running should read as exactly
    // that.
    final misconfigured = kReleaseMode && !AppInfo.pointsAtRealBackend;

    final text = noServer
        ? (misconfigured ? l10n.configWarningBody : l10n.networkError)
        : message!;

    // A live region because this replaces a loading placeholder without
    // any navigation happening: without it the screen silently swaps
    // from shimmer to an error nobody using a screen reader is told
    // about, and the retry button has to be hunted for.
    final content = Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.09),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
            ),
            child: const Icon(Icons.cloud_off_outlined, size: 30, color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.s4),
          // No header flag on the title: the live region above merges the
          // two lines into one announcement, so a heading inside it would
          // mark the whole block as a heading and there would be nothing
          // left to jump to anyway.
          Text(
            l10n.somethingWentWrong,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
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

    if (!scrollable) {
      // Tighter than the full-screen version on purpose: inside a page
      // that already has a header above it, the old 64pt of air pushed
      // the retry button below the fold — the one control on the screen,
      // reachable only by scrolling.
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.s8,
          AppSpacing.pagePadding,
          AppSpacing.s6,
        ),
        child: content,
      );
    }

    return ListView(
      // Always scrollable so a pull-to-refresh still works here — this is
      // exactly the screen someone tugs at when the network comes back.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const SizedBox(height: AppSpacing.s16),
        content,
      ],
    );
  }
}

/// What a screen shows when the request worked and there is simply
/// nothing there yet.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String text;

  /// Optional second line — room for "book your first visit" rather than
  /// leaving someone at a dead end.
  final String? hint;

  final bool scrollable;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.text,
    this.hint,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 30, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.45),
          ),
        ],
      ],
    );

    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: content,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const SizedBox(height: AppSpacing.s16),
        content,
      ],
    );
  }
}
