// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:lpenglis/main.dart';

void main() {
  testWidgets('L’application affiche les quatre onglets principaux', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlashcardsApp());
    await tester.pump();

    expect(find.text('Vocabulaire'), findsOneWidget);
    expect(find.text('Grammaire'), findsOneWidget);
    expect(find.text('Cartes'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Réviser'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
