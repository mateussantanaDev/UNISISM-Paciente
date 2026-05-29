import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Scaffold padrão das telas autenticadas.
/// Aplica background slate-50, padding consistente, max-width pra tablet.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padded = true,
    this.scrollable = true,
    this.maxContentWidth = AppSpacing.contentMaxWidth,
    this.refresh,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool padded;
  final bool scrollable;
  final double maxContentWidth;
  final Future<void> Function()? refresh;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padded) {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingH,
          vertical: AppSpacing.pagePaddingV,
        ),
        child: content,
      );
    }

    content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: content,
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    if (refresh != null) {
      content = RefreshIndicator(
        onRefresh: refresh!,
        color: AppColors.blue900,
        backgroundColor: AppColors.white,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: appBar,
      body: SafeArea(child: content),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// AppBar padrão com título grande e ação opcional.
PreferredSizeWidget appBar({
  required String title,
  String? subtitle,
  Widget? leading,
  List<Widget>? actions,
  bool centerTitle = false,
}) {
  return AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    ),
    centerTitle: centerTitle,
    leading: leading,
    actions: actions,
  );
}
