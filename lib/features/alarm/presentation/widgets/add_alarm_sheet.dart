import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:trying_flutter/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:trying_flutter/features/prayer/presentation/providers/prayer_provider.dart';

/// Bottom sheet for creating or editing a prayer alarm.
class AddAlarmSheet extends ConsumerStatefulWidget {
  final PrayerAlarm? existingAlarm;

  const AddAlarmSheet({super.key, this.existingAlarm});

  @override
  ConsumerState<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends ConsumerState<AddAlarmSheet> {
  late String _selectedPrayer;
  late bool _isBefore;
  late int _offsetMinutes;
  late bool _vibrate;
  late double _volume;

  bool _useCustomOffset = false;

  // Preset offset options in minutes
  static const List<int> _presetOffsets = [5, 10, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlarm;
    if (existing != null) {
      _selectedPrayer = existing.prayerName;
      _isBefore = existing.offset.isNegative;
      _offsetMinutes = existing.offset.inMinutes.abs();
      _vibrate = existing.vibrate;
      _volume = existing.volume;
      _useCustomOffset = !_presetOffsets.contains(_offsetMinutes);
    } else {
      _selectedPrayer = 'Fajr';
      _isBefore = true;
      _offsetMinutes = 30;
      _vibrate = true;
      _volume = 0.8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prayers = ref.watch(prayerTimesProvider).valueOrNull ?? [];
    final prayerNames = prayers.map((p) => p.name).toList();
    final isEditing = widget.existingAlarm != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),

            // Title
            Text(
              isEditing ? 'Edit Alarm' : 'New Alarm',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Prayer selector
            _buildSectionTitle('Prayer Time'),
            const SizedBox(height: 8),
            _buildPrayerSelector(prayerNames),
            const SizedBox(height: 24),

            // Before/After toggle
            _buildSectionTitle('When'),
            const SizedBox(height: 8),
            _buildBeforeAfterToggle(theme),
            const SizedBox(height: 24),

            // Offset selection
            _buildSectionTitle('Offset'),
            const SizedBox(height: 8),
            _buildOffsetSelector(theme),
            const SizedBox(height: 24),

            // Settings
            _buildSectionTitle('Settings'),
            const SizedBox(height: 8),
            _buildSettingsSection(theme),
            const SizedBox(height: 32),

            // Preview
            _buildPreview(theme),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saveAlarm,
              icon: Icon(isEditing ? Icons.save : Icons.add_alarm),
              label: Text(isEditing ? 'Save Changes' : 'Create Alarm'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPrayerSelector(List<String> prayerNames) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prayerNames.map((name) {
        final isSelected = name == _selectedPrayer;
        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _selectedPrayer = name);
          },
        );
      }).toList(),
    );
  }

  Widget _buildBeforeAfterToggle(ThemeData theme) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          label: Text('Before'),
          icon: Icon(Icons.arrow_back),
        ),
        ButtonSegment(
          value: false,
          label: Text('After'),
          icon: Icon(Icons.arrow_forward),
        ),
      ],
      selected: {_isBefore},
      onSelectionChanged: (selection) {
        setState(() => _isBefore = selection.first);
      },
    );
  }

  Widget _buildOffsetSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preset buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presetOffsets.map((min) {
              final isSelected = !_useCustomOffset && _offsetMinutes == min;
              return ChoiceChip(
                label: Text(_formatMinutes(min)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _offsetMinutes = min;
                      _useCustomOffset = false;
                    });
                  }
                },
              );
            }),
            // Custom option
            ChoiceChip(
              label: const Text('Custom'),
              selected: _useCustomOffset,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _useCustomOffset = true);
                }
              },
            ),
          ],
        ),

        // Custom slider
        if (_useCustomOffset) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _formatMinutes(_offsetMinutes),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _offsetMinutes.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
                  label: _formatMinutes(_offsetMinutes),
                  onChanged: (value) {
                    setState(() => _offsetMinutes = value.round());
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Column(
      children: [
        // Vibration toggle
        SwitchListTile.adaptive(
          title: const Text('Vibrate'),
          subtitle: const Text('Vibrate when alarm triggers'),
          secondary: const Icon(Icons.vibration),
          value: _vibrate,
          onChanged: (value) => setState(() => _vibrate = value),
          contentPadding: EdgeInsets.zero,
        ),

        // Volume slider
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.volume_up),
          title: const Text('Volume'),
          subtitle: Slider(
            value: _volume,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(_volume * 100).round()}%',
            onChanged: (value) => setState(() => _volume = value),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final label = PrayerAlarm.generateLabel(
      _selectedPrayer,
      Duration(minutes: _isBefore ? -_offsetMinutes : _offsetMinutes),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '$hours hr';
      return '$hours hr $mins min';
    }
    return '$minutes min';
  }

  void _saveAlarm() {
    final offset = Duration(
      minutes: _isBefore ? -_offsetMinutes : _offsetMinutes,
    );
    final label = PrayerAlarm.generateLabel(_selectedPrayer, offset);

    final alarm = PrayerAlarm(
      id:
          widget.existingAlarm?.id ??
          ref.read(alarmsNotifierProvider.notifier).generateId(),
      prayerName: _selectedPrayer,
      offset: offset,
      label: label,
      isEnabled: widget.existingAlarm?.isEnabled ?? true,
      vibrate: _vibrate,
      volume: _volume,
    );

    final notifier = ref.read(alarmsNotifierProvider.notifier);
    if (widget.existingAlarm != null) {
      notifier.updateAlarm(alarm);
    } else {
      notifier.addAlarm(alarm);
    }

    Navigator.pop(context);
  }
}
