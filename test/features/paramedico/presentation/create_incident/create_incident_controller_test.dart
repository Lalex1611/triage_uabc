import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/features/paramedico/presentation/create_incident/create_incident_controller.dart';

void main() {
  test('el incidente se titula con la categoría elegida', () {
    final c = CreateIncidentController();
    addTearDown(c.dispose);

    expect(c.title, 'Accidente vehicular');

    c.setEmergencyType('incendio_quemadura');
    expect(c.title, 'Incendio o Quemadura');

    c.setEmergencyType('otro');
    expect(c.title, 'Otro');
  });
}
