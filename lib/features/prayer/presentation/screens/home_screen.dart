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
      body: prayerTimesAsync.when(
        data: (prayers) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, now),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chip(
            label: Text(_formatDate(now)),
            backgroundColor: colorScheme.secondaryContainer,
            labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
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

    return Card(
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
                fontFamily: 'monospace',
                letterSpacing: -1,
              ),
            ),
            if (subLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onCardColor.withOpacity(0.8),
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

    return SliverList(
      delegate: SliverChildListDelegate([
        ...prayers.map((m) => _buildPrayerTile(context, m, nextPrayer, now)),
        if (nightMarkers.isNotEmpty) ...[
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Night Markers',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          ...nightMarkers.map(
            (m) => _buildPrayerTile(context, m, nextPrayer, now, isNight: true),
          ),
        ],
        const SizedBox(height: 80), // Bottom padding
      ]),
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

    final textColor = isPassed && !isNext
        ? colorScheme.onSurface.withOpacity(0.5)
        : colorScheme.onSurface;

    final iconColor = isNext
        ? colorScheme.primary
        : (isPassed ? colorScheme.outline : colorScheme.secondary);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: tileColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor.withOpacity(0.7)),
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
