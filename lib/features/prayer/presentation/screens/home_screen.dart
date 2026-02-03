import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/core/utils/date_time_utils.dart';
import 'package:trying_flutter/features/prayer/domain/entities/prayer_time.dart';
import 'package:trying_flutter/features/prayer/presentation/providers/prayer_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);
    final now = ref.watch(tickerProvider).value ?? DateTime.now();

    return Scaffold(
      body: Stack(
        children: [
          // Background image with single blur (performant)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Image.asset(
                'assets/bg.webp',
                fit: BoxFit.cover,
                cacheWidth: 1080, // Limit decoded resolution for performance
              ),
            ),
          ),
          // Dark overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
          // Content
          prayerTimesAsync.when(
            data: (prayers) {
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, now),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: _buildNextPrayerCard(context, nextPrayer, now),
                    ),
                  ),
                  _buildPrayerList(context, prayers, nextPrayer, now),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DateTime now) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar.large(
      title: const Text('Prayer Times'),
      centerTitle: false,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _GlassChip(
            label: _formatDate(now),
            backgroundColor: colorScheme.secondaryContainer,
            labelColor: colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildNextPrayerCard(
    BuildContext context,
    PrayerTime? nextPrayer,
    DateTime now,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    String label = 'Next Prayer';
    String timeStr = '--:--';
    String subLabel = '';
    Color cardColor = colorScheme.primaryContainer;
    Color onCardColor = colorScheme.onPrimaryContainer;

    if (nextPrayer != null) {
      final diff = nextPrayer.time.difference(now);
      label = 'Until ${nextPrayer.name}';
      timeStr = DateTimeUtils.formatDuration(diff);
      subLabel = 'at ${DateTimeUtils.formatTime(nextPrayer.time)}';

      if (nextPrayer.isInIqamahWindow(now)) {
        label = '${nextPrayer.name} Iqamah in';
        timeStr = DateTimeUtils.formatDuration(
          nextPrayer.iqamahTime!.difference(now),
        );
        cardColor = colorScheme.tertiaryContainer;
        onCardColor = colorScheme.onTertiaryContainer;
      }
    } else {
      label = 'No more prayers';
      timeStr = 'Done';
      cardColor = colorScheme.surfaceContainerHighest;
      onCardColor = colorScheme.onSurfaceVariant;
    }

    return _GlassCard(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: onCardColor),
            ),
            const SizedBox(height: 8),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: onCardColor,
                letterSpacing: -1,
              ),
            ),
            if (subLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onCardColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerList(
    BuildContext context,
    List<PrayerTime> markers,
    PrayerTime? nextPrayer,
    DateTime now,
  ) {
    final prayers = markers
        .where((m) => m.isPrayer || m.name == 'Sunrise')
        .toList();
    final nightMarkers = markers
        .where((m) => !m.isPrayer && m.name != 'Sunrise')
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          ...prayers.map((m) => _buildPrayerTile(context, m, nextPrayer, now)),
          if (nightMarkers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Night Markers',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ),
            ...nightMarkers.map(
              (m) =>
                  _buildPrayerTile(context, m, nextPrayer, now, isNight: true),
            ),
          ],
          const SizedBox(height: 80), // Bottom padding
        ]),
      ),
    );
  }

  Widget _buildPrayerTile(
    BuildContext context,
    PrayerTime marker,
    PrayerTime? nextPrayer,
    DateTime now, {
    bool isNight = false,
  }) {
    final isPassed = marker.hasPassed(now);
    final isNext = nextPrayer == marker;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine styles based on state
    Color? tileColor;
    if (isNext) {
      tileColor = colorScheme.primaryContainer;
    }

    final textColor = isPassed && !isNext ? Colors.white54 : Colors.white;

    final iconColor = isNext
        ? colorScheme.primary
        : (isPassed ? Colors.white38 : colorScheme.secondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // Wider gap between items
      child: _GlassCard(
        color: tileColor,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(_getMarkerIcon(marker), color: iconColor, size: 28),
          title: Text(
            marker.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          subtitle: Text(
            marker.arabicName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateTimeUtils.formatTime(marker.time),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: isNext ? FontWeight.w900 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (marker.iqamahTime != null)
                Text(
                  'Iqamah: ${DateTimeUtils.formatTime(marker.iqamahTime!)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colorScheme.tertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMarkerIcon(PrayerTime marker) {
    if (marker.name == 'Sunrise') return Icons.wb_sunny;
    if (marker.name.contains('Third') || marker.name == 'Midnight') {
      return Icons.nightlight_round;
    }
    if (marker.isPrayer) return Icons.mosque;
    return Icons.schedule;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Performant glass card - uses solid semi-transparent color instead of blur
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _GlassCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Glass Chip for the date display
class _GlassChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color labelColor;

  const _GlassChip({
    required this.label,
    required this.backgroundColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}
