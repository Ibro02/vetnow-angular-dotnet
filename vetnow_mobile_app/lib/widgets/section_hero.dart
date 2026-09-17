import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'hero_shell.dart';

/// Shared gradient hero used at the top of Profile and Appointments so
/// the two always have the exact same height and rhythm — same
/// leading-icon size, same title/subtitle line count, same chip row.
/// Don't hand-roll a similar-but-slightly-different hero elsewhere;
/// extend this one instead so heights stay locked together.
class SectionHero extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget? titleBadge;
  final String subtitle;
  final List<Widget> chips;

  const SectionHero({
    super.key,
    required this.leading,
    required this.title,
    this.titleBadge,
    required this.subtitle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    // The panel — swept edge, layering, gold rim, shadow — is the same
    // HeroSurface the Explore header uses. Sharing it is the point: four
    // screens that each rebuilt "a gradient with rounded corners" are
    // four screens that slowly stop matching.
    return SizedBox(
      width: double.infinity,
      child: HeroSurface(
        background: const _GoldBloom(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.s6,
            AppSpacing.pagePadding,
            AppSpacing.s8,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 56, width: 56, child: leading),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                          ),
                        ),
                        if (titleBadge != null) ...[
                          const SizedBox(width: 8),
                          titleBadge!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              for (int i = 0; i < chips.length; i++) ...[
                if (i != 0) const SizedBox(width: AppSpacing.s3),
                Expanded(child: chips[i]),
              ],
            ],
          ),
        ],
    );
  }
}

/// Warm bloom in the bottom-right, echoing the gold used for ratings and
/// the member badge so the palette reads as chosen rather than assorted.
class _GoldBloom extends StatelessWidget {
  const _GoldBloom();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -50,
            bottom: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.20),
                    AppColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const HeroChip({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    // The same glass as the chips on the Explore header: lit along the
    // top edge, fading down. The edge is what sells it — without one the
    // chip dissolves into the gradient instead of sitting on top of it.
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          // Expanded, not a bare Column: the icon beside it is a fixed
          // 28pt, so on a narrow phone two of these chips side by side
          // pushed the text past the edge — 30 pixels of it, striped
          // yellow and black.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
