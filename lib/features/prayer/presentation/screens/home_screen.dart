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
      backgroundColor: const Color(0xFF1a1a2e), // Keep original background
      body: SafeArea(
        child: prayerTimesAsync.when(
          data: (prayers) {
            return Column(
              children: [
                _buildHeader(now).animate().fadeIn().slideY(begin: -0.2),
                _buildMainDisplay(nextPrayer, now).animate().fadeIn().scale(),
                Expanded(child: _buildPrayerList(prayers, nextPrayer, now)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Prayer Times',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(now),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDisplay(PrayerTime? nextPrayer, DateTime now) {
    String label = 'Next Prayer';
    String timeStr = '--:--';
    Color accentColor = Colors.cyanAccent;

    // Simple logic for display (can be enhanced with full PrayerStatus logic if needed)
    if (nextPrayer != null) {
      final diff = nextPrayer.time.difference(now);
      label = 'Until ${nextPrayer.name}';
      timeStr = DateTimeUtils.formatDuration(diff);

      // Iqamah check (simplified)
      if (nextPrayer.isInIqamahWindow(now)) {
        label = '${nextPrayer.name} Iqamah in';
        timeStr = DateTimeUtils.formatDuration(
          nextPrayer.iqamahTime!.difference(now),
        );
        accentColor = Colors.orangeAccent;
      }
    } else {
      label = 'No more prayers';
      timeStr = 'Done';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          if (nextPrayer != null) ...[
            const SizedBox(height: 12),
            Text(
              'at ${DateTimeUtils.formatTime(nextPrayer.time)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerList(
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...prayers.map(
          (m) =>
              _buildMarkerTile(m, nextPrayer, now).animate().fadeIn().slideX(),
        ),
        const SizedBox(height: 20),
        if (nightMarkers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Night Markers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ).animate().fadeIn(),
          ...nightMarkers.map(
            (m) => _buildMarkerTile(
              m,
              nextPrayer,
              now,
              isNightMarker: true,
            ).animate().fadeIn().slideX(),
          ),
        ],
      ],
    );
  }

  Widget _buildMarkerTile(
    PrayerTime marker,
    PrayerTime? nextPrayer,
    DateTime now, {
    bool isNightMarker = false,
  }) {
    final isPassed = marker.hasPassed(now);
    final isNext = nextPrayer == marker; // Object equality thanks to Equatable

    // Logic for "Current" (just passed) is a bit trickier without PrayerStatus,
    // but we can infer: if passed and next is distinct, maybe it's "current"?
    // For now, let's just highlight Next.

    Color tileColor;
    if (isNext) {
      tileColor = Colors.cyanAccent.withValues(alpha: 0.15);
    } else {
      tileColor = Colors.white.withValues(alpha: 0.05);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: isNext
            ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getMarkerColor(marker, isPassed).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _getMarkerEmoji(marker),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marker.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPassed && !isNext
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white,
                  ),
                ),
                Text(
                  marker.arabicName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateTimeUtils.formatTime(marker.time),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPassed && !isNext
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              if (marker.iqamahTime != null)
                Text(
                  'Iqamah: ${DateTimeUtils.formatTime(marker.iqamahTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orangeAccent.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMarkerColor(PrayerTime marker, bool isPassed) {
    if (isPassed) return Colors.grey;
    if (marker.isPrayer) return Colors.greenAccent;
    if (marker.name == 'Sunrise') return Colors.orangeAccent;
    return Colors.purpleAccent;
  }

  String _getMarkerEmoji(PrayerTime marker) {
    switch (marker.name) {
      case 'Fajr':
        return '🌙';
      case 'Sunrise':
        return '🌅';
      case 'Dhuhr':
        return '☀️';
      case 'Asr':
        return '🌤️';
      case 'Maghrib':
        return '🌇';
      case 'Isha':
        return '🌃';
      case 'First Third':
        return '🌑';
      case 'Midnight':
        return '🕛';
      case 'Last Third':
        return '✨';
      default:
        return '🕌';
    }
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
