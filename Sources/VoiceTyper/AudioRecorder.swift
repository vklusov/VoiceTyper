import AVFoundation

class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var converter: AVAudioConverter?
    private var recordedFrames: AVAudioFramePosition = 0

    private func findBestInputNode(engine: AVAudioEngine) -> AVAudioNode? {
        let session = AVAudioSession.sharedInstance()
        guard let inputs = session.availableInputs else {
            print("AudioRecorder: no inputs available, using default")
            return engine.inputNode
        }

        print("AudioRecorder: available inputs:")
        for input in inputs {
            let isDefault = input == session.currentRoute.inputs.first
            print("  - \(input.portName) (\(input.portType.rawValue)) def=\(isDefault)")
        }

        // Prefer built-in mic, then any non-virtual, non-hue input
        let preferred = inputs.first { input in
            let name = input.portName.lowercased()
            return !name.contains("hue") && !name.contains("blackhole")
                && input.portType != .virtual
        }

        if let preferred = preferred {
            print("AudioRecorder: selecting '\(preferred.portName)'")
            do {
                try session.setPreferredInput(preferred)
                return engine.inputNode
            } catch {
                print("AudioRecorder: failed to set input: \(error), using default")
            }
        }
        return engine.inputNode
    }

    func startRecording() {
        let engine = AVAudioEngine()
        recordedFrames = 0

        // Configure audio session for recording
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            print("AudioRecorder: session config failed: \(error)")
        }

        let inputNode = findBestInputNode(engine: engine)
        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        let tempDir = FileManager.default.temporaryDirectory
        outputURL = tempDir.appendingPathComponent("voicetyper_recording.wav")
        guard let outputURL = outputURL else { return }

        try? FileManager.default.removeItem(at: outputURL)

        do {
            audioFile = try AVAudioFile(
                forWriting: outputURL,
                settings: targetFormat.settings,
                commonFormat: .pcmFormatInt16,
                interleaved: false
            )

            converter = AVAudioConverter(from: hardwareFormat, to: targetFormat)

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, time in
                guard let self, let converter = self.converter,
                      let outputBuffer = AVAudioPCMBuffer(
                        pcmFormat: targetFormat,
                        frameCapacity: AVAudioFrameCount(buffer.frameLength)
                      )
                else { return }

                var errorPointer: NSError?
                let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }

                converter.convert(to: outputBuffer, error: &errorPointer, withInputFrom: inputBlock)
                if errorPointer == nil {
                    try? self.audioFile?.write(from: outputBuffer)
                    self.recordedFrames += Int64(outputBuffer.frameLength)
                }
            }

            engine.prepare()
            try engine.start()
            audioEngine = engine

        } catch {
            print("AudioRecorder: ❌ failed: \(error)")
            audioEngine = nil
            audioFile = nil
        }
    }

    func stopRecording() -> Data? {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        audioFile = nil
        converter = nil

        let durationMs = recordedFrames > 0 ? Int(Double(recordedFrames) / 16000.0 * 1000.0) : 0
        print("AudioRecorder: stopped, frames=\(recordedFrames), duration=\(durationMs)ms")

        guard let outputURL = outputURL else {
            print("AudioRecorder: no output URL")
            return nil
        }
        let data = try? Data(contentsOf: outputURL)
        print("AudioRecorder: file size=\(data?.count ?? -1) bytes")
        return data
    }
}
