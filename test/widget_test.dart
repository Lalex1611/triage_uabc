import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/auth/presentation/login/login_screen.dart';
import 'package:sistema_triage/main.dart';

void main() {
  testWidgets('app loads login route', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
