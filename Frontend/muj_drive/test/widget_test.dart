import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muj_drive/main.dart';

void main() {
  testWidgets('InitialScreen shows welcome text and two buttons',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MUJDriveApp());

    // Should see the headline
    expect(find.text('Welcome To MUJ Drive'), findsOneWidget);

    // Should see both role‑selection buttons
    expect(find.text('I am a Student'), findsOneWidget);
    expect(find.text('I am a Driver'), findsOneWidget);
  });
}
