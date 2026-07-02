import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/features/auth/esqueci_senha_page.dart';
import '../../presentation/features/auth/login_page.dart';
import '../../presentation/features/auth/splash_page.dart';
import '../../presentation/features/banners/banner_detail_page.dart';
import '../../presentation/features/dossie/atendimento_detail_page.dart';
import '../../presentation/features/dossie/dossie_atendimentos_page.dart';
import '../../presentation/features/dossie/dossie_exames_page.dart';
import '../../presentation/features/dossie/dossie_page.dart';
import '../../presentation/features/dossie/dossie_vacinacoes_page.dart';
import '../../presentation/features/dossie/exame_detail_page.dart';
import '../../presentation/features/dossie/vacinacao_detail_page.dart';
import '../../presentation/features/encaminhamento/encaminhamento_anexos_page.dart';
import '../../presentation/features/encaminhamento/encaminhamento_detail_page.dart';
import '../../presentation/features/encaminhamento/encaminhamento_timeline_page.dart';
import '../../presentation/features/encaminhamento/encaminhamentos_list_page.dart';
import '../../presentation/features/home/home_page.dart';
import '../../presentation/features/main_shell.dart';
import '../../presentation/features/notificacoes/notificacoes_page.dart';
import '../../presentation/features/onboarding/onboarding_page.dart';
import '../../presentation/features/perfil/ajuda_page.dart';
import '../../presentation/features/perfil/perfil_page.dart';
import '../../presentation/features/perfil/preferencias_notificacao_page.dart';
import '../../presentation/features/perfil/trocar_senha_page.dart';
import '../../presentation/features/tfd/tfd_detail_solicitacao_page.dart';
import '../../presentation/features/tfd/tfd_list_page.dart';
import '../../presentation/features/tfd/tfd_solicitar_page.dart';
import '../../presentation/features/ubs/falar_com_ubs_page.dart';
import '../../presentation/features/ubs/minha_ubs_page.dart';
import '../../providers/auth_controller.dart';

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

/// Transição padrão entre páginas: **fade + slide horizontal suave**.
/// 280ms — rápido o suficiente pra não atrasar o operador, devagar o bastante
/// pra dar sensação de continuidade visual.
CustomTransitionPage<void> _page({
  required Widget child,
  String? name,
  Object? arguments,
}) {
  return CustomTransitionPage<void>(
    name: name,
    arguments: arguments,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Transição vertical (modal sheet style) — usado em telas que sobem como modal.
CustomTransitionPage<void> _modalPage({required Widget child, String? name}) {
  return CustomTransitionPage<void>(
    name: name,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Fade puro — usado entre abas da bottom nav, e splash → login/home.
CustomTransitionPage<void> _fadePage({required Widget child, String? name}) {
  return CustomTransitionPage<void>(
    name: name,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    child: child,
    transitionsBuilder: (_, anim, __, c) => FadeTransition(opacity: anim, child: c),
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this.ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/',
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/login') ||
          location.startsWith('/esqueci-senha');
      const trocarSenhaPath = '/perfil/trocar-senha';

      if (auth.status == AuthStatus.checking) {
        return location == '/' ? null : '/';
      }
      if (!auth.isAuthenticated) {
        return isAuthRoute || location == '/login' ? null : '/login';
      }
      // Senha provisória: força o paciente a trocar antes de liberar
      // qualquer outra rota. Sinalizado por `paciente.senhaProvisoria=true`
      // vindo do backend no login/me.
      if (auth.requiresPasswordChange) {
        return location == trocarSenhaPath ? null : trocarSenhaPath;
      }
      if (isAuthRoute || location == '/') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => _fadePage(child: const SplashPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) => _fadePage(child: const LoginPage()),
      ),
      GoRoute(
        path: '/esqueci-senha',
        pageBuilder: (_, __) => _page(child: const EsqueciSenhaPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) => _fadePage(child: const OnboardingPage()),
      ),

      ShellRoute(
        navigatorKey: _shellNavKey,
        pageBuilder: (context, state, child) =>
            _fadePage(child: MainShell(child: child)),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => _fadePage(child: const HomePage()),
          ),
          GoRoute(
            path: '/dossie',
            pageBuilder: (_, __) => _fadePage(child: const DossiePage()),
          ),
          GoRoute(
            path: '/notificacoes',
            pageBuilder: (_, __) => _fadePage(child: const NotificacoesPage()),
          ),
          GoRoute(
            path: '/perfil',
            pageBuilder: (_, __) => _fadePage(child: const PerfilPage()),
          ),
        ],
      ),

      // Encaminhamentos
      GoRoute(
        path: '/encaminhamentos',
        pageBuilder: (_, __) =>
            _page(child: const EncaminhamentosListPage()),
      ),
      GoRoute(
        path: '/encaminhamento/:id',
        pageBuilder: (_, s) => _page(
            child: EncaminhamentoDetailPage(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/encaminhamento/:id/timeline',
        pageBuilder: (_, s) => _page(
            child: EncaminhamentoTimelinePage(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/encaminhamento/:id/anexos',
        pageBuilder: (_, s) => _page(
            child: EncaminhamentoAnexosPage(id: s.pathParameters['id']!)),
      ),

      // Dossiê
      GoRoute(
        path: '/dossie/atendimentos',
        pageBuilder: (_, __) =>
            _page(child: const DossieAtendimentosPage()),
      ),
      GoRoute(
        path: '/dossie/vacinacoes',
        pageBuilder: (_, __) => _page(child: const DossieVacinacoesPage()),
      ),
      GoRoute(
        path: '/dossie/exames',
        pageBuilder: (_, __) => _page(child: const DossieExamesPage()),
      ),
      GoRoute(
        path: '/dossie/atendimento/:id',
        pageBuilder: (_, s) => _page(
            child: AtendimentoDetailPage(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/dossie/vacinacao/:id',
        pageBuilder: (_, s) => _page(
            child: VacinacaoDetailPage(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/dossie/exame/:id',
        pageBuilder: (_, s) => _page(
            child: ExameDetailPage(id: s.pathParameters['id']!)),
      ),

      // TFD
      GoRoute(
        path: '/tfd',
        pageBuilder: (_, __) => _page(child: const TfdListPage()),
      ),
      GoRoute(
        path: '/tfd/solicitar/:viagemId',
        pageBuilder: (_, s) => _modalPage(
            child: TfdSolicitarPage(viagemId: s.pathParameters['viagemId']!)),
      ),
      GoRoute(
        path: '/tfd/solicitacao/:id',
        pageBuilder: (_, s) => _page(
            child: TfdDetailSolicitacaoPage(id: s.pathParameters['id']!)),
      ),

      // UBS
      GoRoute(
        path: '/ubs',
        pageBuilder: (_, __) => _page(child: const MinhaUbsPage()),
      ),
      GoRoute(
        path: '/ubs/falar',
        pageBuilder: (_, __) => _modalPage(child: const FalarComUbsPage()),
      ),

      // Banners
      GoRoute(
        path: '/banner/:id',
        pageBuilder: (_, s) =>
            _page(child: BannerDetailPage(id: s.pathParameters['id']!)),
      ),

      // Perfil sub-rotas
      GoRoute(
        path: '/perfil/trocar-senha',
        pageBuilder: (_, __) => _modalPage(child: const TrocarSenhaPage()),
      ),
      GoRoute(
        path: '/perfil/notificacoes',
        pageBuilder: (_, __) =>
            _page(child: const PreferenciasNotificacaoPage()),
      ),
      GoRoute(
        path: '/perfil/ajuda',
        pageBuilder: (_, __) => _page(child: const AjudaPage()),
      ),
    ],
  );
});
