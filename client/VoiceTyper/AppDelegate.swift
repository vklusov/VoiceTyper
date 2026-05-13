import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    private let recorder = AudioRecorder()
    private let client = VoiceTyperClient()
    
    private var isRecording = false
    private var settings = Settings()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "VoiceTyper")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: StatusBarView(settings: settings)
        )
        
        // Register hotkey
        setupHotkey()
    }
    
    private func setupHotkey() {
        // Register Option+Space hotkey
        // Uses CGEvent keyboard shortcut monitoring
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Option+Space (keyCode 49 = Space)
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                self?.toggleRecording()
            }
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recorder.startRecording()
        updateIcon(isRecording: true)
    }
    
    private func stopRecording() {
        isRecording = false
        updateIcon(isRecording: false)
        
        guard let audioData = recorder.stopRecording() else { return }
        
        // Send to server
        Task {
            do {
                let result = try await client.transcribe(
                    audioData: audioData,
                    cleanWithLLM: settings.cleanWithLLM,
                    language: settings.language
                )
                
                let text = settings.cleanWithLLM && result.cleaned != nil
                    ? result.cleaned!
                    : result.raw
                
                // Paste to active window
                PasteManager.paste(text: text)
                
            } catch {
                print("Transcription error: \(error)")
            }
        }
    }
    
    private func updateIcon(isRecording: Bool) {
        DispatchQueue.main.async {
            let iconName = isRecording ? "mic.circle.fill" : "mic.circle"
            self.statusItem.button?.image = NSImage(
                systemSymbolName: iconName,
                accessibilityDescription: "VoiceTyper"
            )
        }
    }
}
