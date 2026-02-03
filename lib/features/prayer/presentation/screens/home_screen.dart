import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/core/utils/date_time_utils.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:trying_flutter/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:trying_flutter/features/alarm/presentation/screens/alarm_settings_screen.dart';
import 'package:trying_flutter/features/alarm/presentation/widgets/add_alarm_sheet.dart';
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
                  _buildPrayerList(context, ref, prayers, nextPrayer, now),
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
        // Alarm settings button
        IconButton(
          icon: const Icon(Icons.alarm),
          tooltip: 'Alarm Settings',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AlarmSettingsScreen(),
              ),
            );
          },
        ),
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
    WidgetRef ref,
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
          ...prayers.map(
            (m) => _buildPrayerTile(context, ref, m, nextPrayer, now),
          ),
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
              (m) => _buildPrayerTile(
                context,
                ref,
                m,
                nextPrayer,
                now,
                isNight: true,
              ),
            ),
          ],
          const SizedBox(height: 80), // Bottom padding
        ]),
      ),
    );
  }

  Widget _buildPrayerTile(
    BuildContext context,
    WidgetRef ref,
    PrayerTime marker,
    PrayerTime? nextPrayer,
    DateTime now, {
    bool isNight = false,
  }) {
    final isPassed = marker.hasPassed(now);
    final isNext = nextPrayer == marker;
    final colorScheme = Theme.of(context).colorScheme;
    final hasAlarm = ref.watch(prayerHasAlarmProvider(marker.name));

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
          title: Row(
            children: [
              Text(
                marker.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
              if (hasAlarm) ...[
                const SizedBox(width: 6),
                Icon(Icons.alarm, size: 16, color: colorScheme.tertiary),
              ],
            ],
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
          onTap: () {
            // Quick alarm setup for this prayer
            _showQuickAlarmSheet(context, marker.name);
          },
        ),
      ),
    );
  }

  void _showQuickAlarmSheet(BuildContext context, String prayerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickAlarmSheet(prayerName: prayerName),
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

/// Quick alarm sheet for setting common alarm offsets directly from prayer tiles
class _QuickAlarmSheet extends ConsumerWidget {
  final String prayerName;

  const _QuickAlarmSheet({required this.prayerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alarms = ref.watch(alarmsProvider);
    final existingAlarms = alarms
        .where((a) => a.prayerName == prayerName)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Icon(Icons.alarm_add, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Set Alarm for $prayerName',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick preset buttons
          Text(
            'Before',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 30, 60].map((min) {
              return ActionChip(
                avatar: const Icon(Icons.alarm, size: 18),
                label: Text(_formatMin(min)),
                onPressed: () => _createAlarm(context, ref, -min),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text(
            'After',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 30].map((min) {
              return ActionChip(
                avatar: const Icon(Icons.alarm, size: 18),
                label: Text(_formatMin(min)),
                onPressed: () => _createAlarm(context, ref, min),
              );
            }).toList(),
          ),

          // Existing alarms for this prayer
          if (existingAlarms.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Active Alarms',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...existingAlarms.map(
              (alarm) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.alarm_on,
                  color: alarm.isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(alarm.label),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    ref
                        .read(alarmsNotifierProvider.notifier)
                        .deleteAlarm(alarm.id);
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // More options button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Open full alarm sheet with this prayer pre-selected
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddAlarmSheet(
                  existingAlarm: PrayerAlarm(
                    id: ref.read(alarmsNotifierProvider.notifier).generateId(),
                    prayerName: prayerName,
                    offset: const Duration(minutes: -30),
                    label: PrayerAlarm.generateLabel(
                      prayerName,
                      const Duration(minutes: -30),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: const Text('More Options'),
          ),
        ],
      ),
    );
  }

  String _formatMin(int minutes) {
    if (minutes >= 60) {
      return '${minutes ~/ 60} hr';
    }
    return '$minutes min';
  }

  void _createAlarm(BuildContext context, WidgetRef ref, int offsetMinutes) {
    final offset = Duration(minutes: offsetMinutes);
    final label = PrayerAlarm.generateLabel(prayerName, offset);
    final alarm = PrayerAlarm(
      id: ref.read(alarmsNotifierProvider.notifier).generateId(),
      prayerName: prayerName,
      offset: offset,
      label: label,
    );

    ref.read(alarmsNotifierProvider.notifier).addAlarm(alarm);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm set: $label'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(alarmsNotifierProvider.notifier).deleteAlarm(alarm.id);
          },
        ),
      ),
    );
  }
}
