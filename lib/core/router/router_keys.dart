import 'package:flutter/material.dart';

/// Navigator raíz del [GoRouter] (rutas paramédicas full-screen con `parentNavigatorKey`)
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
