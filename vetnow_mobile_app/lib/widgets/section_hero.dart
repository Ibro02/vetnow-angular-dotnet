import 'package:flutter/material.dart';
import '../config/theme.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s6, AppSpacing.pagePadding, AppSpacing.s6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ink, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl2),
          bottomRight: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
