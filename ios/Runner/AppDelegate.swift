import AVFoundation
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Keep other audio (Music, podcasts) ducking under Vortixa's SFX.
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    try? AVAudioSession.sharedInstance().setActive(true)

    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    // Register before Dart configures Firebase so the APNs token is not missed.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
