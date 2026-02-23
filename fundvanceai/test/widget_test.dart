// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fundvanceai/main.dart';

void main() {
  testWidgets('Onboarding screen loads on first launch',
      (WidgetTester tester) async {
    // Build the app simulating first launch (onboarding not yet seen)
    await tester.pumpWidget(const FundVanceApp(onboardingDone: false));
    await tester.pump();

    // Onboarding first page should show the app name
    expect(find.text('FundVance AI'), findsWidgets);
  });
}
