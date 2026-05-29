import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Bloco de skeleton com pulse animado. Usar como placeholder de loading.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.color,
  });

  final double? width;
  final double height;
  final Color? color;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppColors.slate100;
    final highlight = AppColors.slate200;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Color.lerp(base, highlight, _ctrl.value),
        );
      },
    );
  }
}

/// Skeleton de um card grande (StatusHeroCard placeholder).
class HeroCardSkeleton extends StatelessWidget {
  const HeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.slate50,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: const [
                Skeleton(width: 56, height: 56),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Skeleton(width: 100, height: 10),
                      SizedBox(height: 8),
                      Skeleton(width: 180, height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: double.infinity, height: 16),
                SizedBox(height: 8),
                Skeleton(width: 220, height: 16),
                SizedBox(height: AppSpacing.lg),
                Skeleton(width: 180, height: 14),
                SizedBox(height: 8),
                Skeleton(width: 240, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de um IconCard.
class IconCardSkeleton extends StatelessWidget {
  const IconCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.slate200, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: const [
          Skeleton(width: 56, height: 56),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Skeleton(width: 180, height: 16),
                SizedBox(height: 8),
                Skeleton(width: 240, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton lista (genérico).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 5});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => const IconCardSkeleton(),
    );
  }
}
