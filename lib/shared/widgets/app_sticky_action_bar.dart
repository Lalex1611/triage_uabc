import 'package:flutter/material.dart';

/// Barra inferior fija para botones de acción (confirmar / cancelar)
class AppStickyActionBar extends StatelessWidget {
  AppStickyActionBar({
    super.key,
    this.children,
    this.child,
    this.barHeight = 56,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
  }) : assert(
         child != null || (children != null && children.isNotEmpty),
         'Provide child or children',
       );

  final List<Widget>? children;
  final Widget? child;
  final double barHeight;
  final Color backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final row =
        child ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _intersperse(children!, const SizedBox(width: 12)),
        );

    return Material(
      color: backgroundColor,
      elevation: elevation,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: row,
          ),
        ),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return items;
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(separator);
      out.add(items[i]);
    }
    return out;
  }
}

/// Distribución de dos botones principales (acción secundaria a la izquierda, principal a la derecha)
class AppStickyActionRow extends StatelessWidget {
  const AppStickyActionRow({
    super.key,
    required this.leading,
    required this.trailing,
    this.leadingFlex = 4,
    this.trailingFlex = 6,
  });

  final Widget leading;
  final Widget trailing;
  final int leadingFlex;
  final int trailingFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(flex: leadingFlex, child: leading),
        const SizedBox(width: 12),
        Expanded(flex: trailingFlex, child: trailing),
      ],
    );
  }
}
