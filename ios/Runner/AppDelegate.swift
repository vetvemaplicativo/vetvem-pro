import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Força o registro remoto de push já no boot do app, em vez de depender
    // só do timing do plugin firebase_messaging (que às vezes não dispara o
    // registro nativo a tempo, deixando o APNs token nulo pra sempre —
    // "apns-token-not-set"). Chamada pura UIKit, sem depender do Firebase.
    application.registerForRemoteNotifications()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
