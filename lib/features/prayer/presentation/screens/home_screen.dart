import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/core/utils/date_time_utils.dart';
import 'package:trying_flutter/core/widgets/glass_widgets.dart';
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
          child: GlassChip(
            label: DateTimeUtils.formatDate(now),
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

    return GlassCard(
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
              (m) => _buildPrayerTile(context, ref, m, nextPrayer, now),
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
    DateTime now,
  ) {
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
      child: GlassCard(
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
                _buildAlarmChip(context, ref, marker.name, colorScheme),
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

  Widget _buildAlarmChip(
    BuildContext context,
    WidgetRef ref,
    String prayerName,
    ColorScheme colorScheme,
  ) {
    final alarms = ref.watch(prayerAlarmsProvider(prayerName));
    if (alarms.isEmpty) return const SizedBox.shrink();

    // Show first alarm offset only, very minimal
    final firstAlarm = alarms.first;
    final offsetMin = firstAlarm.offset.inMinutes;
    final label = offsetMin == 0
        ? 'At'
        : '${offsetMin > 0 ? '+' : ''}$offsetMin min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm, size: 12, color: colorScheme.tertiary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (alarms.length > 1)
            Text(
              ' +${alarms.length - 1}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.tertiary.withValues(alpha: 0.7),
              ),
            ),
        ],
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
                label: Text(DateTimeUtils.formatMinutes(min)),
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
                label: Text(DateTimeUtils.formatMinutes(min)),
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
  }
}
