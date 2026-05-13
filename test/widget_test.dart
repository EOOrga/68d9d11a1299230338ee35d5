import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laforet_sylvie_francoise/main.dart';

void main() {
  testWidgets('navigates core operations sections', (tester) async {
    await tester.pumpWidget(const LaforetOperationsApp(screenshotMode: true));

    expect(find.text('LAFORET Ops'), findsOneWidget);
    expect(find.text('Campus Nord'), findsWidgets);
    expect(find.text('New operations record'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.event_available_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Boardroom booking for vendor visit'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();
    expect(find.text('HVAC filters'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('On-device session'), findsOneWidget);
  });

  testWidgets('creates a local work record', (tester) async {
    await tester.pumpWidget(const LaforetOperationsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create-record-title')),
      'Replace delivery dock signage',
    );
    await tester.tap(find.byKey(const Key('save-record')));
    await tester.pumpAndSettle();

    expect(find.text('Replace delivery dock signage'), findsOneWidget);
  });
}
