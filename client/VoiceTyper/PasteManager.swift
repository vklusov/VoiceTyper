import Cocoa
import Carbon

class PasteManager {
    
    /// Вставляет текст в активное окно через Accessibility API
    static func paste(text: String) {
        DispatchQueue.main.async {
            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            // Small delay to let pasteboard update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Simulate Cmd+V
                let source = CGEventSource(stateID: .combinedSessionState)
                
                let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
                let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
                
                keyVDown?.flags = .maskCommand
                keyVUp?.flags = .maskCommand
                
                keyVDown?.post(tap: .cghidEventTap)
                keyVUp?.post(tap: .cghidEventTap)
            }
        }
    }
}
