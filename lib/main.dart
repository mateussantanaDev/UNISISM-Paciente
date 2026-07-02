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
  // Status bar discreta — combina com o design B2G claro.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Push (ntfy.sh) — falha silenciosa: app continua funcionando sem push.
  try {
    await PushService.instance.init();
  } catch (_) {/* nice-to-have */}

  runApp(const ProviderScope(child: UnisismApp()));
}

class UnisismApp extends ConsumerStatefulWidget {
  const UnisismApp({super.key});

  @override
  ConsumerState<UnisismApp> createState() => _UnisismAppState();
}

class _UnisismAppState extends ConsumerState<UnisismApp> {
  bool _wired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    if (_wired) return;
    _wired = true;

    // ─── 1. 401 fatal → força logout (limpa estado UI) ──
    ref.read(apiClientProvider).onUnauthorized = () {
      ref.read(refreshSchedulerProvider).cancel();
      ref.read(authControllerProvider.notifier).logout();
    };

    // ─── 2. Login/Refresh → registra push + agenda refresh proativo ──
    // ─── Logout → cancela timer ──
    ref.listenManual<AuthState>(authControllerProvider, (prev, next) async {
      final logou = (prev?.status == AuthStatus.authenticated) &&
          next.status == AuthStatus.unauthenticated;
      if (logou) {
        ref.read(refreshSchedulerProvider).cancel();
        return;
      }

      if (next.status == AuthStatus.authenticated && next.paciente != null) {
        // Registra push token no backend (best-effort).
        final fcm = PushService.instance.fcmToken;
        if (fcm != null) {
          try {
            await ref.read(authRepositoryProvider).registrarDispositivo(
                  fcmToken: fcm,
                  plataforma: defaultTargetPlatform.name,
                );
          } catch (_) {/* não crítico */}
        }

        // Agenda refresh proativo (5 min antes do access expirar).
        // Sessões antigas sem `expiresAt` no model pulam — fallback reativo.
        await _agendarRefreshProativo();
      }
    });

    // ─── 3. Deep link de notificação → navegação ──
    final router = ref.read(routerProvider);
    PushService.instance.onDeepLink.listen((link) {
      router.push(link);
    });

    // ─── 4. Topic UUID gerado/renovado → registra no backend ──
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

  /// Agenda o refresh proativo. Usa `expiresIn` padrão (30 min) quando o
  /// estado não tiver `expiresAt` específico — auth_controller só guarda
  /// o `Paciente`, não a `Sessao` completa.
  Future<void> _agendarRefreshProativo() async {
    final api = ref.read(apiClientProvider);
    final hasRefresh = await api.getRefreshToken();
    if (hasRefresh == null || hasRefresh.isEmpty) return;
    // Default 30min — bate com `expiresIn: 1800` do backend v0.18+.
    final expiresAt = DateTime.now().add(const Duration(minutes: 30));
    ref.read(refreshSchedulerProvider).schedule(expiresAt: expiresAt);
  }

  @override
  void dispose() {
    PushService.instance.dispose();
    super.dispose();
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
