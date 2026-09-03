import Flutter
import UIKit

/// UserDefaults slot that hands a launch-tap URL to Dart.
///
/// Written only when a scene connects because of a notification response.
/// Taps on an already-running app go through firebase_messaging instead.
///
/// Key must stay `flutter.vxdrop_tap_route` — SharedPreferences on the
/// Dart side reads `vxdrop_tap_route`.
enum VtLaunchSlot {
  static let routeKey = "flutter.vxdrop_tap_route"

  private static let flatKeys = ["deep_link", "target", "url", "deeplink", "link"]

  static func park(_ payload: [AnyHashable: Any]) {
    guard let url = pickUrl(from: payload) else { return }
    let store = UserDefaults.standard
    store.set(url, forKey: routeKey)
    store.synchronize()

    #if DEBUG
    NSLog("[VT.SLOT] parked launch destination")
    #endif
  }

  private static func pickUrl(from payload: [AnyHashable: Any]) -> String? {
    if let direct = webLink(in: payload) { return direct }

    for container in ["payload", "data"] {
      guard let nested = payload[container] as? [AnyHashable: Any] else { continue }
      if let found = webLink(in: nested) { return found }
    }
    return nil
  }

  private static func webLink(in fields: [AnyHashable: Any]) -> String? {
    for key in flatKeys {
      guard let raw = fields[key] as? String else { continue }
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard
        let parsed = URL(string: trimmed),
        let scheme = parsed.scheme?.lowercased(),
        scheme == "https" || scheme == "http",
        parsed.host?.isEmpty == false
      else { continue }
      return trimmed
    }
    return nil
  }
}

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let response = connectionOptions.notificationResponse {
      VtLaunchSlot.park(response.notification.request.content.userInfo)
    }

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
