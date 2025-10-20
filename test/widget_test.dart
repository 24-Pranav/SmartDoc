// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_doc/main.dart';
import 'package:smart_doc/providers/user_provider.dart';
import 'package:smart_doc/screens/splash_screen.dart';

void main() {
  testWidgets('App starts and shows SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => UserProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that SplashScreen is shown initially.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
