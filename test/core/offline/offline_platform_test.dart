import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/medico/data/offline/medico_offline_runtime.dart';
import 'package:sistema_triage/features/paramedico/data/offline/paramedico_offline_runtime.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedico_incidents_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ambos roles habilitan las capturas solo en Android e iOS nativos',
    () async {
      final medico = MedicoOfflineRuntime.instance;
      final paramedico = ParamedicoOfflineRuntime.instance;
      final repository = ParamedicoIncidentsRepository();
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        final mobile =
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;
        final available = !kIsWeb && mobile;
        expect(medico.supported, available, reason: platform.name);
        expect(paramedico.supported, available, reason: platform.name);
        expect(repository.usesLocalCaptures, available, reason: platform.name);
        if (!available) {
          await Future.wait([medico.start(), paramedico.start()]);
          expect(medico.error, isNull);
          expect(paramedico.error, isNull);
        }
      }
    },
  );
}
