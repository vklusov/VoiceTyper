import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    private let recorder = AudioRecorder()
    private let client = VoiceTyperClient()

    private var isRecording = false
    private var settings = VTConfig()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "VoiceTyper")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: StatusBarView(settings: settings)
        )

        setupHotkey()
    }

    nonisolated private func setupHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                Task { @MainActor [weak self] in
                    self?.toggleRecording()
                }
            }
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    func startRecording() {
        isRecording = true
        recorder.startRecording()
        updateIcon(isRecording: true)
    }

    func stopRecording() {
        isRecording = false
        updateIcon(isRecording: false)
        guard let audioData = recorder.stopRecording() else { return }

        let client = self.client
        let settings = self.settings
        Task {
            do {
                let result = try await client.transcribe(
                    audioData: audioData,
                    cleanWithLLM: settings.cleanWithLLM,
                    language: settings.language.rawValue
                )
                let text = settings.cleanWithLLM && result.cleaned != nil ? result.cleaned! : result.raw
                PasteManager.paste(text: text)
            } catch {
                print("Transcription error: \(error)")
            }
        }
    }

    func updateIcon(isRecording: Bool) {
        let iconName = isRecording ? "mic.circle.fill" : "mic.circle"
        statusItem.button?.image = NSImage(
            systemSymbolName: iconName,
            accessibilityDescription: "VoiceTyper"
        )
    }
}
