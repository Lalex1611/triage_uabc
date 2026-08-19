import 'package:flutter/material.dart';
import 'package:sistema_triage/core/config/supabase_env.dart';
import 'package:sistema_triage/core/router/paramedico_stack_nav.dart';
import 'package:sistema_triage/features/paramedico/data/repositories/paramedic_notifications_repository.dart';
import 'package:sistema_triage/features/paramedico/presentation/shared/paramedico_notifications_action.dart';

enum QuickPatientRegistrationPhase { idle, error }

// Orquestador del tab Paciente: abre registro sin incidente (incidente al confirmar)
class QuickPatientRegistrationController extends ChangeNotifier {
  QuickPatientRegistrationController({
    ParamedicNotificationsRepository? notificationsRepository,
  }) : _notificationsRepo = notificationsRepository ?? ParamedicNotificationsRepository();

  final ParamedicNotificationsRepository _notificationsRepo;

  QuickPatientRegistrationPhase phase = QuickPatientRegistrationPhase.idle;
  String? errorMessage;
  bool _running = false;
  int unreadNotifications = 0;

  Future<void> refreshNotifications() async {
    unreadNotifications = await ParamedicoNotificationsAction.unreadCount(_notificationsRepo);
    notifyListeners();
  }

  Future<void> launchRegistration(BuildContext context) async {
    if (_running) return;
    if (!SupabaseEnv.isConfigured) {
      phase = QuickPatientRegistrationPhase.error;
      errorMessage = 'Supabase no configurado.';
      notifyListeners();
      return;
    }

    _running = true;
    errorMessage = null;
    phase = QuickPatientRegistrationPhase.idle;
    notifyListeners();

    try {
      await pushParamedicoFullScreen(context, '/paramedico/registro-rapido/registrar');
    } catch (e) {
      if (!context.mounted) return;
      phase = QuickPatientRegistrationPhase.error;
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      _running = false;
    }
  }

  Future<void> openNotifications(BuildContext context) async {
    await ParamedicoNotificationsAction.open(
      context,
      repository: _notificationsRepo,
      onUnreadChanged: (count) {
        unreadNotifications = count;
        notifyListeners();
      },
    );
  }
}
