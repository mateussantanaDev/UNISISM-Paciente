import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unisism_paciente/core/theme/app_theme.dart';
import 'package:unisism_paciente/presentation/features/auth/splash_page.dart';
import 'package:unisism_paciente/presentation/shared/widgets/widgets.dart';

void main() {
  group('Smoke tests', () {
    testWidgets('Splash renderiza a marca UNISISM', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const SplashPage(),
          ),
        ),
      );
      expect(find.text('UNISISM'), findsOneWidget);
      expect(find.text('PACIENTE'), findsOneWidget);
    });

    testWidgets('PrimaryButton renderiza label e responde a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PrimaryButton(label: 'Entrar', onPressed: () => taps++),
          ),
        ),
      );
      expect(find.text('Entrar'), findsOneWidget);
      await tester.tap(find.text('Entrar'));
      expect(taps, 1);
    });

    testWidgets('StatusBadge mapeia status conhecido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(child: StatusBadge.fromStatus('AGUARDANDO_REGULACAO')),
          ),
        ),
      );
      expect(find.textContaining('REGULAÇÃO'), findsOneWidget);
    });
  });
}
