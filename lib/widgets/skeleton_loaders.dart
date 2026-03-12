import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading widgets for smooth loading states
class SkeletonLoader extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey.shade300,
      highlightColor: highlightColor ?? Colors.grey.shade100,
      child: child,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SkeletonCircle(size: 50),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 150, height: 16),
                      SizedBox(height: 8),
                      SkeletonText(width: double.infinity, height: 12),
                      SizedBox(height: 4),
                      SkeletonText(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonVocabularyCard extends StatelessWidget {
  const SkeletonVocabularyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonCircle(size: 70),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 120, height: 24),
                      SizedBox(height: 8),
                      SkeletonText(width: 180, height: 16),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SkeletonText(width: double.infinity, height: 60),
          ],
        ),
      ),
    );
  }
}

class SkeletonStoryCard extends StatelessWidget {
  const SkeletonStoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  const SkeletonCircle(size: 20),
                ],
              ),
              const SizedBox(height: 16),
              const SkeletonText(width: 200, height: 20),
              const SizedBox(height: 8),
              const SkeletonText(width: double.infinity, height: 14),
              const SizedBox(height: 4),
              const SkeletonText(width: double.infinity, height: 14),
              const SizedBox(height: 4),
              const SkeletonText(width: 150, height: 14),
              const Spacer(),
              const Row(
                children: [
                  SkeletonCircle(size: 16),
                  SizedBox(width: 8),
                  SkeletonText(width: 60, height: 12),
                  SizedBox(width: 16),
                  SkeletonCircle(size: 16),
                  SizedBox(width: 8),
                  SkeletonText(width: 60, height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonQuizCard extends StatelessWidget {
  const SkeletonQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const SkeletonCircle(size: 50),
            const SizedBox(height: 20),
            const SkeletonText(width: double.infinity, height: 20),
            const SizedBox(height: 8),
            const SkeletonText(width: 200, height: 20),
            const SizedBox(height: 32),
            ...List.generate(4, (index) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonCard(height: 56, borderRadius: 12),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            height: 200,
            color: Colors.white,
          ),
          Transform.translate(
            offset: const Offset(0, -50),
            child: const SkeletonCircle(size: 100),
          ),
          const SizedBox(height: 16),
          const SkeletonText(width: 150, height: 24),
          const SizedBox(height: 8),
          const SkeletonText(width: 200, height: 16),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    SkeletonText(width: 60, height: 32),
                    SizedBox(height: 4),
                    SkeletonText(width: 60, height: 14),
                  ],
                ),
                Column(
                  children: [
                    SkeletonText(width: 60, height: 32),
                    SizedBox(height: 4),
                    SkeletonText(width: 60, height: 14),
                  ],
                ),
                Column(
                  children: [
                    SkeletonText(width: 60, height: 32),
                    SizedBox(height: 4),
                    SkeletonText(width: 60, height: 14),
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

class SkeletonStats extends StatelessWidget {
  const SkeletonStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(width: 120, height: 20),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SkeletonText(width: 60, height: 32),
                      SizedBox(height: 4),
                      SkeletonText(width: 80, height: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SkeletonText(width: 60, height: 32),
                      SizedBox(height: 4),
                      SkeletonText(width: 80, height: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SkeletonText(width: 60, height: 32),
                      SizedBox(height: 4),
                      SkeletonText(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SkeletonText(width: double.infinity, height: 12),
            SizedBox(height: 8),
            SkeletonCard(height: 8, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
