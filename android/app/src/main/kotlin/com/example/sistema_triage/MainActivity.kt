package com.example.sistema_triage

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "triage/offline_storage")
            .setMethodCallHandler { call, result ->
                if (call.method != "protectedDirectory") {
                    result.notImplemented()
                } else {
                    val directory = File(noBackupFilesDir, "triage_captures")
                    if (directory.isDirectory || directory.mkdirs()) {
                        result.success(directory.absolutePath)
                    } else {
                        result.error("storage", "No se pudo abrir el almacenamiento protegido", null)
                    }
                }
            }
    }
}
