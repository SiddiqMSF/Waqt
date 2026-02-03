import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:trying_flutter/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:trying_flutter/features/alarm/presentation/widgets/add_alarm_sheet.dart';

/// Screen for managing all prayer alarms.
class AlarmSettingsScreen extends ConsumerWidget {
  const AlarmSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Prayer Alarms'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: alarmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading alarms: $e')),
        data: (alarms) => alarms.isEmpty
            ? _buildEmptyState(context)
            : _buildAlarmList(context, ref, alarms),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlarmSheet(context, ref),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add Alarm'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No alarms set',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first alarm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAlarmList(
    BuildContext context,
    WidgetRef ref,
    List<PrayerAlarm> alarms,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return _AlarmCard(
          key: ValueKey(alarm.id),
          alarm: alarm,
          onToggle: (enabled) {
            ref
                .read(alarmsNotifierProvider.notifier)
                .toggleAlarm(alarm.id, enabled);
          },
          onEdit: () => _showEditAlarmSheet(context, ref, alarm),
          onDelete: () => _confirmDelete(context, ref, alarm),
        ).animate().fadeIn(
          duration: 200.ms,
          delay: Duration(milliseconds: index * 50),
        );
      },
    );
  }

  void _showAddAlarmSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAlarmSheet(),
    );
  }

  void _showEditAlarmSheet(
    BuildContext context,
    WidgetRef ref,
    PrayerAlarm alarm,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmSheet(existingAlarm: alarm),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PrayerAlarm alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text('Delete "${alarm.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(alarmsNotifierProvider.notifier).deleteAlarm(alarm.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying an alarm
class _AlarmCard extends StatelessWidget {
  final PrayerAlarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = alarm.isEnabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.alarm,
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              title: Text(
                alarm.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? null : theme.colorScheme.outline,
                ),
              ),
              subtitle: Text(
                alarm.prayerName,
                style: TextStyle(
                  color: isEnabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.outline,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  Switch.adaptive(value: isEnabled, onChanged: onToggle),
                ],
              ),
              onLongPress: onDelete,
            ),
          ),
        ),
      ),
    );
  }
}
