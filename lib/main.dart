import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_triage/core/config/load_supabase_runtime.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/connectivity/app_connectivity_notifier.dart';
import 'package:sistema_triage/core/router/app_router.dart';
import 'package:sistema_triage/core/session/auth_gate.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/shared/widgets/offline_connection_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadSupabaseRuntimeAsset();

  if (SupabaseEnv.isConfigured) {
    await Supabase.initialize(
      url: SupabaseEnv.projectUrl,
      anonKey: SupabaseEnv.anonKey,
    );
  }

  await AuthGate.instance.initialize();
  await AppConnectivityNotifier.instance.start();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Triage',
      theme: appTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned.fill(child: OfflineConnectionBanner()),
            ],
          ),
        );
      },
    );
  }
}
