// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate App Icons', (WidgetTester tester) async {
    // 1. App Icon (Original)
    final svgFile = File('assets/logo.svg');
    if (!svgFile.existsSync()) {
      fail('assets/logo.svg not found');
    }
    final svgString = svgFile.readAsStringSync();

    print('Generating assets/logo.png...');
    await _generateIcon(tester, svgString, 'assets/logo.png', 1024);

    // 2. Notification Icon (White)
    // Replace fill color with white. Original is #e3e3e3.
    final svgWhite = svgString.replaceAll('#e3e3e3', '#FFFFFF');

    // Ensure the directory exists
    Directory('android/app/src/main/res/drawable').createSync(recursive: true);
    print(
      'Generating android/app/src/main/res/drawable/ic_notification.png...',
    );
    await _generateIcon(
      tester,
      svgWhite,
      'android/app/src/main/res/drawable/ic_notification.png',
      512,
    );
  });
}

Future<void> _generateIcon(
  WidgetTester tester,
  String svgContent,
  String outputPath,
  double size,
) async {
  final key = GlobalKey();

  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: size,
            height: size,
            child: SvgPicture.string(
              svgContent,
              width: size,
              height: size,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  ui.Image image = await boundary.toImage(pixelRatio: 1.0);
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    File(outputPath).writeAsBytesSync(byteData.buffer.asUint8List());
    print('Generated $outputPath');
  } else {
    print('Failed to generate $outputPath');
  }
}
