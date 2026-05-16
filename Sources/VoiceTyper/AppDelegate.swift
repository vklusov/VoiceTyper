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
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: StatusBarView(settings: settings)
        )

        logToFile("App launched")
        setupHotkey()
    }

    private func logToFile(_ msg: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let logURL = home.appendingPathComponent("Desktop/voicetyper_debug.log")
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            handle.write((msg + "\n").data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? msg.data(using: .utf8)?.write(to: logURL)
        }
    }

    private func setupHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self, event.keyCode == 0x36 else { return }
            let isPressed = event.modifierFlags.contains(.command)
            DispatchQueue.main.async { [weak self] in
                if isPressed {
                    self?.startRecording()
                } else {
                    self?.stopRecording()
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

    func startRecording() {
        isRecording = true
        recorder.startRecording()
        setIcon(systemName: "mic.circle.fill", tint: .red)
        logToFile("🔴 Recording started")
    }

    func stopRecording() {
        isRecording = false
        setIcon(systemName: "mic.circle.fill", tint: .systemOrange)
        logToFile("🟠 Processing...")

        guard let audioData = recorder.stopRecording() else {
            logToFile("❌ no audio data")
            resetIcon()
            return
        }

        logToFile("Got \(audioData.count) bytes")

        let client = self.client
        let settings = self.settings
        Task {
            do {
                let result = try await client.transcribe(
                    audioData: audioData,
                    cleanWithLLM: settings.cleanWithLLM,
                    language: settings.language.rawValue
                )
                logToFile("✅ Transcribed: '\(result.raw)'")
                let text = settings.cleanWithLLM && result.cleaned != nil ? result.cleaned! : result.raw
                logToFile("Paste: '\(text)'")

                // Wait for paste to fully complete before resetting icon
                await withCheckedContinuation { continuation in
                    PasteManager.paste(text: text) {
                        continuation.resume()
                    }
                }
            } catch {
                logToFile("❌ ERROR: \(error.localizedDescription)")
            }
            resetIcon()
            logToFile("⚪ Idle")
        }
    }

    private func setIcon(systemName: String, tint: NSColor?) {
        guard let button = statusItem.button else { return }
        if let t = tint {
            let img = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
            let config = NSImage.SymbolConfiguration(paletteColors: [t])
            button.image = img?.withSymbolConfiguration(config)
        } else {
            button.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        }
        button.needsDisplay = true
    }

    private func resetIcon() {
        setIcon(systemName: "mic.circle", tint: nil)
    }
}
