import 'package:flutter/material.dart';
import 'package:sistema_triage/core/layout/app_responsive.dart';

/// Estructura de scroll único para pantalla principal
class HomeScreenBody extends StatelessWidget {
  const HomeScreenBody({
    super.key,
    required this.header,
    required this.slivers,
    this.onRefresh,
    this.isLoading = false,
    this.loadingWidget,
    this.useSafeArea = true,
    this.bottomInset = 88,
  });

  /// Encabezado superior (búsqueda, filtros, resumen)
  final List<Widget> header;

  /// Lista principal de contenido (tarjetas o estado vacío)
  final List<Widget> slivers;

  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final Widget? loadingWidget;
  final bool useSafeArea;

  /// Margen inferior para barra o botones flotantes
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final footerPad = bottomInset + context.bottomNavExtent * 0.2;

    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: header,
          ),
        ),
        if (isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: loadingWidget ??
                const Center(child: CircularProgressIndicator()),
          )
        else ...slivers,
        SliverToBoxAdapter(child: SizedBox(height: footerPad)),
      ],
    );

    Widget body = scrollView;
    if (onRefresh != null) {
      body = RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
    }

    if (!useSafeArea) return body;
    return SafeArea(bottom: false, child: body);
  }
}
