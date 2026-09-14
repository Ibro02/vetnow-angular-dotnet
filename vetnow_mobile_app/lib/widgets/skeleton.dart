import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Loading placeholders shaped like the content that is coming.
///
/// These replace a centred spinner. The wait is the same length either
/// way, but a page that already has its layout reads as *loading* rather
/// than as *stalled*, and nothing jumps when the real data lands —
/// the skeleton occupies the same space the card will.
///
/// The shimmer is a gradient swept across the placeholder by a single
/// looping controller per widget, deliberately slow (1.4s) and low
/// contrast so it reads as a surface catching light rather than a
/// flashing element.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Sweep from off-screen left to off-screen right so the
            // highlight enters and leaves rather than fading in place.
            final travel = _controller.value * 3 - 1;
            return LinearGradient(
              begin: Alignment(travel - 0.6, -0.2),
              end: Alignment(travel + 0.6, 0.2),
              colors: const [
                Color(0x00FFFFFF),
                Color(0xB3FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single grey block standing in for a line of text or an image.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Stand-in for one clinic card on Explore. Mirrors the real card's
/// geometry — 96pt image block on the left, three lines on the right —
/// so the list doesn't reflow when the data arrives.
class ClinicCardSkeleton extends StatelessWidget {
  const ClinicCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      // No `stretch` here: the row has no height of its own to stretch to,
      // and asking for one throws an infinite-constraint layout error. The
      // 108pt block on the left is what gives the card its height.
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              bottomLeft: Radius.circular(AppRadius.xl),
            ),
            child: SkeletonBox(width: 96, height: 108, radius: 0),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(width: 150, height: 13),
                  SizedBox(height: 9),
                  SkeletonBox(width: 190, height: 11),
                  SizedBox(height: 11),
                  Row(
                    children: [
                      SkeletonBox(width: 26, height: 22, radius: AppRadius.sm),
                      SizedBox(width: 5),
                      SkeletonBox(width: 26, height: 22, radius: AppRadius.sm),
                      SizedBox(width: 5),
                      SkeletonBox(width: 26, height: 22, radius: AppRadius.sm),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stand-in for one appointment card.
class AppointmentCardSkeleton extends StatelessWidget {
  const AppointmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 160, height: 14),
              SkeletonBox(width: 70, height: 20, radius: AppRadius.full),
            ],
          ),
          SizedBox(height: 12),
          SkeletonBox(width: 130, height: 11),
          SizedBox(height: 8),
          SkeletonBox(width: 110, height: 11),
          SizedBox(height: 8),
          SkeletonBox(width: 150, height: 11),
        ],
      ),
    );
  }
}

/// Stand-in for one review.
class ReviewSkeleton extends StatelessWidget {
  const ReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 24, height: 24, radius: AppRadius.full),
              SizedBox(width: 6),
              SkeletonBox(width: 80, height: 11),
            ],
          ),
          SizedBox(height: 9),
          SkeletonBox(width: 90, height: 11),
          SizedBox(height: 9),
          SkeletonBox(height: 10),
          SizedBox(height: 6),
          SkeletonBox(width: 200, height: 10),
        ],
      ),
    );
  }
}

/// Convenience: a shimmering column of [count] identical skeletons.
class SkeletonList extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const SkeletonList({super.key, this.count = 3, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: List.generate(count, (_) => itemBuilder()),
      ),
    );
  }
}
