import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/services/push_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_controller.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await PushService.instance.init();

  runApp(const ProviderScope(child: UnisismApp()));
}

class UnisismApp extends ConsumerStatefulWidget {
  const UnisismApp({super.key});

  @override
  ConsumerState<UnisismApp> createState() => _UnisismAppState();
}

class _UnisismAppState extends ConsumerState<UnisismApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    ref.read(apiClientProvider).onUnauthorized = () {
      ref.read(authControllerProvider.notifier).logout();
    };

    // listenManual: ref.listen() exige estar dentro do build() — aqui estamos
    // num callback postFrame, então usamos a variante manual.
    ref.listenManual<AuthState>(authControllerProvider, (prev, next) async {
      if (next.status == AuthStatus.authenticated && next.paciente != null) {
        final fcm = PushService.instance.fcmToken;
        if (fcm == null) return;
        try {
          await ref.read(authRepositoryProvider).registrarDispositivo(
                fcmToken: fcm,
                plataforma: defaultTargetPlatform.name,
              );
        } catch (_) {/* não crítico */}
      }
    });

    final router = ref.read(routerProvider);
    PushService.instance.onDeepLink.listen((link) {
      router.push(link);
    });
    PushService.instance.onTokenRefresh = (token) async {
      if (ref.read(authControllerProvider).isAuthenticated) {
        try {
          await ref.read(authRepositoryProvider).registrarDispositivo(
                fcmToken: token,
                plataforma: defaultTargetPlatform.name,
              );
        } catch (_) {/* não crítico */}
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'UNISISM Paciente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
    );
  }
}
