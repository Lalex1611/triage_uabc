import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TriageOfflineStorage") else { return }
    let channel = FlutterMethodChannel(name: "triage/offline_storage", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "protectedDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let manager = FileManager.default
        var directory = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask,
          appropriateFor: nil, create: true).appendingPathComponent("triage_captures", isDirectory: true)
        try manager.createDirectory(at: directory, withIntermediateDirectories: true,
          attributes: [.protectionKey: FileProtectionType.complete])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        result(directory.path)
      } catch {
        result(FlutterError(code: "storage", message: "No se pudo abrir el almacenamiento protegido", details: nil))
      }
    }
  }
}
