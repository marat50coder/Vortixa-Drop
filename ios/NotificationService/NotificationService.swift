import UserNotifications

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

/// Rich notification wrapper for Vortixa Drop.
/// Firebase Messaging fills attachments; this type only guarantees a
/// mutable copy reaches `contentHandler`, including when the 30s OS
/// timer fires first.
final class NotificationService: UNNotificationServiceExtension {
  private var handoff: ((UNNotificationContent) -> Void)?
  private var draft: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    handoff = contentHandler
    draft = request.content.mutableCopy() as? UNMutableNotificationContent

    guard let draft else {
      contentHandler(request.content)
      return
    }

    #if canImport(FirebaseMessaging)
    Messaging.serviceExtension().populateNotificationContent(
      draft,
      withContentHandler: contentHandler
    )
    #else
    contentHandler(draft)
    #endif
  }

  override func serviceExtensionTimeWillExpire() {
    guard let handoff, let draft else { return }
    handoff(draft)
  }
}
