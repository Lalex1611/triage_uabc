import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sistema_triage/features/paramedico/presentation/map/paramedico_map_controller.dart';

void main() {
  test('"Cerca de mí" incluye hasta 5 km y deja fuera lo que pasa de ahí', () {
    const user = LatLng(32.5149, -117.0382);
    const distance = Distance();
    LatLng at(double meters) => distance.offset(user, meters, 45);

    expect(ParamedicoMapController.isNearby(user, at(4900)), isTrue);
    expect(ParamedicoMapController.isNearby(user, at(5100)), isFalse);
  });
}
