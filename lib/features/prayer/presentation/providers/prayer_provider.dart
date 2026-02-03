import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/core/services/location_service.dart';
import 'package:trying_flutter/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:trying_flutter/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:trying_flutter/features/prayer/domain/entities/prayer_time.dart';
import 'package:trying_flutter/features/prayer/domain/repositories/prayer_repository.dart';

// Repository Provider
final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl();
});

// Location Service Provider with dependency injection
final locationServiceProvider = Provider<LocationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationService(prefs);
});

// Timer Provider to tick every minute
final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now());
});

// Prayer Times Provider
final prayerTimesProvider = FutureProvider<List<PrayerTime>>((ref) async {
  final repository = ref.watch(prayerRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);

  // Get coordinates (assuming getCoordinates returns value or throws)
  final coords = await locationService.getCoordinates();

  return repository.getPrayerTimes(
    latitude: coords.latitude,
    longitude: coords.longitude,
  );
});

// Current Status Provider (Reactive to Time and Prayers)
final nextPrayerProvider = Provider<PrayerTime?>((ref) {
  final prayersAsync = ref.watch(prayerTimesProvider);
  final now = DateTime.now();

  // Rebuild every minute to keep 'next' accurate if we cross a prayer time
  ref.watch(tickerProvider);

  return prayersAsync.when(
    data: (prayers) {
      final repository = ref.watch(prayerRepositoryProvider);
      // Logic to find next prayer
      // If none found for today, could check tomorrow (but for now simple logic)
      return repository.getNextPrayer(prayers, now);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

// State class for complex status if needed, but separate providers work well too
// For now, let's keep it simple with providers.
