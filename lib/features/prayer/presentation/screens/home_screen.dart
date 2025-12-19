import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      // Material 3 defaults to surface color, so we don't need to force one.
      // But for a premium feel with glass, a subtle background is nice.
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
                  child: _buildNextPrayerCard(
                    context,
                    nextPrayer,
                    now,
                  ).animate().fadeIn().scale(),
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
      title: Text(
        'Prayer Times',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      surfaceTintColor: colorScheme.surfaceTint,
      backgroundColor: colorScheme.surface.withValues(
        alpha: 0.8,
      ), // Translucent for glass effect behind status bar
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
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

    // Glassmorphic Card
    return Card(
      elevation: 0,
      color: cardColor.withValues(alpha: 0.3), // Transparent container
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cardColor.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                      color: onCardColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
      tileColor = colorScheme.primaryContainer.withValues(
        alpha: 0.3,
      ); // Highlight next
    } else if (isPassed) {
      tileColor = null; // Standard transparent
    } else {
      tileColor = null;
    }

    final textColor = isPassed && !isNext
        ? colorScheme.onSurface.withValues(alpha: 0.5) // Dim passed
        : colorScheme.onSurface;

    final iconColor = isNext
        ? colorScheme.primary
        : (isPassed ? colorScheme.outline : colorScheme.secondary);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 0,
      color:
          tileColor ??
          Colors
              .transparent, // Transparent for plain list feeling or highlighted
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            _getMarkerEmoji(marker),
            style: const TextStyle(fontSize: 20),
          ),
        ),
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
    ).animate().fadeIn().slideX();
  }

  String _getMarkerEmoji(PrayerTime marker) {
    if (marker.name == 'Sunrise') return '🌅';
    if (marker.name.contains('Third') || marker.name == 'Midnight') return '🌑';
    if (marker.isPrayer) return '🕌';
    return '⏱️';
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
