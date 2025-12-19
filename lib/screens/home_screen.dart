import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/prayer_marker.dart';
import '../services/prayer_time_service.dart';
import '../utils/date_time_utils.dart';

class HomeScreen extends StatefulWidget {
  final PrayerTimeService prayerService;

  const HomeScreen({super.key, required this.prayerService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  late List<PrayerMarker> _markers;
  late PrayerStatus _status;

  @override
  void initState() {
    super.initState();
    // Initialize data synchronously (no setState)
    final now = DateTime.now();
    _markers = widget.prayerService.getMarkersForDate(now);
    _status = widget.prayerService.getCurrentStatus(now);

    // Start timer after first frame to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateData();
      });
    });
  }

  void _updateData() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _markers = widget.prayerService.getMarkersForDate(now);
      _status = widget.prayerService.getCurrentStatus(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header with current status
            _buildHeader(),
            // Main countdown/countup display
            _buildMainDisplay(),
            // Prayer times list
            Expanded(child: _buildPrayerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            _formatDate(DateTime.now()),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDisplay() {
    String label;
    String time;
    Color accentColor;

    if (_status.isInIqamahPeriod) {
      label = '${_status.currentMarker!.name} Iqamah in';
      time = DateTimeUtils.formatDuration(_status.timeUntilIqamah);
      accentColor = Colors.orangeAccent;
    } else if (_status.isInCountupPeriod) {
      label = 'Since ${_status.currentMarker!.name}';
      time = DateTimeUtils.formatDuration(_status.timeSinceCurrent);
      accentColor = Colors.greenAccent;
    } else {
      label = 'Until ${_status.nextMarker?.name ?? "Next Prayer"}';
      time = DateTimeUtils.formatDuration(_status.timeUntilNext);
      accentColor = Colors.cyanAccent;
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
            time,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          if (_status.nextMarker != null && !_status.isInCountupPeriod) ...[
            const SizedBox(height: 12),
            Text(
              'at ${DateTimeUtils.formatTime(_status.nextMarker!.time)}',
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

  Widget _buildPrayerList() {
    // Separate prayers and night markers
    final prayers = _markers
        .where((m) => m.isPrayer || m.name == 'Sunrise')
        .toList();
    final nightMarkers = _markers
        .where(
          (m) =>
              m.name == 'First Third' ||
              m.name == 'Midnight' ||
              m.name == 'Last Third',
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Prayer times section
        ...prayers.map((marker) => _buildMarkerTile(marker)),

        const SizedBox(height: 20),

        // Night markers section
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
        ),
        ...nightMarkers.map(
          (marker) => _buildMarkerTile(marker, isNightMarker: true),
        ),
      ],
    );
  }

  Widget _buildMarkerTile(PrayerMarker marker, {bool isNightMarker = false}) {
    final now = DateTime.now();
    final isPassed = marker.hasPassed(now);
    final isNext = _status.nextMarker?.name == marker.name;
    final isCurrent = _status.currentMarker?.name == marker.name;

    Color tileColor;
    if (isNext) {
      tileColor = Colors.cyanAccent.withValues(alpha: 0.15);
    } else if (isCurrent && _status.isInCountupPeriod) {
      tileColor = Colors.greenAccent.withValues(alpha: 0.15);
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
          // Icon
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
          // Name and Arabic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marker.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPassed && !isCurrent
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
          // Time and iqamah
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateTimeUtils.formatTime(marker.time),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPassed && !isCurrent
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

  Color _getMarkerColor(PrayerMarker marker, bool isPassed) {
    if (isPassed) return Colors.grey;
    if (marker.isPrayer) return Colors.greenAccent;
    if (marker.name == 'Sunrise') return Colors.orangeAccent;
    return Colors.purpleAccent; // Night markers
  }

  String _getMarkerEmoji(PrayerMarker marker) {
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
