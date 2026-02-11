// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fundvanceai/main.dart';

void main() {
  testWidgets('App loads and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FundVanceApp());

    // Verify that the welcome text is displayed
    expect(find.text('Welcome to FundVance AI'), findsOneWidget);
    expect(find.text('Your AI-powered financial assistant'), findsOneWidget);
    
    // Verify that the Get Started button exists
    expect(find.text('Get Started'), findsOneWidget);
    
    // Verify the wallet icon is displayed
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
  });
}
