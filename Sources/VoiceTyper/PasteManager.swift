import Cocoa
import UserNotifications
import OSLog

class PasteManager {
    private static let log = Logger(subsystem: "com.vklusov.VoiceTyper", category: "PasteManager")

    static func paste(text: String, completion: @escaping () -> Void = {}) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion()
            return
        }

        log.info("Copying to clipboard: \(trimmed.prefix(60))")

        DispatchQueue.main.async {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(trimmed, forType: .string)

            // Try AppleScript Cmd+V
            var err: NSDictionary?
            var pasteFailed = true
            let script = "tell application \"System Events\" to keystroke \"v\" using command down"
            if let so = NSAppleScript(source: script) {
                so.executeAndReturnError(&err)
                if err == nil {
                    pasteFailed = false
                    log.info("Pasted via Cmd+V")
                }
            }

            // Show notification
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, _ in
                let content = UNMutableNotificationContent()
                content.title = "VoiceTyper"
                if pasteFailed {
                    content.body = "\(trimmed.prefix(80)) — ⌘V to paste"
                } else {
                    content.body = String(trimmed.prefix(100))
                }
                UNUserNotificationCenter.current().add(
                    UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                )
            }

            completion()
        }
    }
}
