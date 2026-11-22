import 'package:sistema_triage/core/offline/offline_capture_store.dart';
import 'package:sistema_triage/core/offline/offline_sync_service.dart';

export 'package:sistema_triage/core/offline/offline_sync_service.dart'
    show CaptureRemote;

typedef ParamedicoSyncService = OfflineSyncService;

class SupabaseCaptureRemote extends SupabaseOfflineCaptureRemote {
  SupabaseCaptureRemote(super.client);

  @override
  Future<Capture> create(
    String account,
    String kind,
    String id,
    Capture payload,
  ) async => Capture.from(
    await client
            .rpc(
              'sync_paramedic_capture',
              params: {
                'p_account_id': account,
                'p_kind': kind,
                'p_sync_client_id': id,
                'p_payload': payload,
              },
            )
            .timeout(SupabaseOfflineCaptureRemote.timeout)
        as Map,
  );
  @override
  Future<void> link(
    String account,
    String kind,
    String remoteId,
    Capture photo,
  ) async {
    await client
        .rpc(
          'link_paramedic_capture_photo',
          params: {
            'p_account_id': account,
            'p_kind': kind,
            'p_record_id': remoteId,
            'p_path': photoPath(remoteId, photo),
          },
        )
        .timeout(SupabaseOfflineCaptureRemote.timeout);
  }
}
