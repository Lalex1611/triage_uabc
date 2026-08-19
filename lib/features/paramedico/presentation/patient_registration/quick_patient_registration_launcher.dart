/// Puente para que el shell dispare el registro rápido al pulsar el tab Paciente
class QuickPatientRegistrationLauncher {
  QuickPatientRegistrationLauncher._();

  static void Function()? _onRequest;

  static void register(void Function() handler) {
    _onRequest = handler;
  }

  static void unregister() {
    _onRequest = null;
  }

  static void request() {
    _onRequest?.call();
  }
}
