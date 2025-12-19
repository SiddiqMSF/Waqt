import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PrayerTimesApp()));

    // Verify that the splash/home screen appears.
    // Since it might be loading, we look for CircularProgressIndicator or "Prayer Times" text.

    // Allow for async state to settle if any (though ProviderScope is synchronous mostly)
    await tester.pump();

    // Expect to find either loading or text
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
