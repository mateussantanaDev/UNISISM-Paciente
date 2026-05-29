import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/notificacao_controller.dart';
import '../shared/widgets/icon_card.dart';

/// Shell com bottom nav de 4 abas pra paciente.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _Tab(path: '/home', icon: Icons.home_outlined, iconActive: Icons.home, label: 'Início'),
    _Tab(path: '/dossie', icon: Icons.medical_information_outlined, iconActive: Icons.medical_information, label: 'Saúde'),
    _Tab(
      path: '/notificacoes',
      icon: Icons.notifications_none,
      iconActive: Icons.notifications,
      label: 'Avisos',
    ),
    _Tab(path: '/perfil', icon: Icons.person_outline, iconActive: Icons.person, label: 'Perfil'),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final naoLidasAsync = ref.watch(naoLidasCountProvider);
    final naoLidas = naoLidasAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 76,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final active = _indexFor(location) == i;
                return Expanded(
                  child: Material(
                    color: AppColors.white,
                    child: InkWell(
                      onTap: () {
                        if (location != t.path) context.go(t.path);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: active
                              ? const Border(
                                  top: BorderSide(color: AppColors.blue900, width: 3),
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Container fixo de 48dp pra acomodar o ícone +
                            // badge sem precisar de Positioned negativo
                            // (que estourava parent data dirty no semantics)
                            SizedBox(
                              width: 48,
                              height: 32,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    active ? t.iconActive : t.icon,
                                    size: 28,
                                    color: active
                                        ? AppColors.blue900
                                        : AppColors.slate600,
                                  ),
                                  if (t.path == '/notificacoes' && naoLidas > 0)
                                    Align(
                                      alignment: const Alignment(1.4, -1.2),
                                      child: CountBadge(count: naoLidas),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? AppColors.blue900 : AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.path,
    required this.icon,
    required this.iconActive,
    required this.label,
  });
  final String path;
  final IconData icon;
  final IconData iconActive;
  final String label;
}
