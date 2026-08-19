import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Rutas bajo `/paramedico/...` con [parentNavigatorKey] en el router: usar el
/// [GoRouter] del árbol (p. ej. desde una pestaña del shell) basta; el fallo de
/// “solo se refresca” venía del redirect del padre `/paramedico`, ya corregido
Future<T?> pushParamedicoFullScreen<T>(
  BuildContext context,
  String location, {
  Object? extra,
}) {
  return GoRouter.of(context).push<T>(location, extra: extra);
}
