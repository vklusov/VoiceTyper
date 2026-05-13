import AVFoundation

class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    
    func startRecording() {
        let audioSession = AVAudioApplication.shared
        // Request permission if needed
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        
        // 16kHz, 16bit, mono
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
        
        // Create temp file
        let tempDir = FileManager.default.temporaryDirectory
        outputURL = tempDir.appendingPathComponent("voicetyper_recording.wav")
        
        guard let outputURL = outputURL else { return }
        
        // Remove old file if exists
        try? FileManager.default.removeItem(at: outputURL)
        
        do {
            audioFile = try AVAudioFile(
                forWriting: outputURL,
                settings: format.settings,
                commonFormat: .pcmFormatInt16,
                interleaved: false
            )
            
            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, time in
                try? self?.audioFile?.write(from: buffer)
            }
            
            engine.prepare()
            try engine.start()
            audioEngine = engine
            
        } catch {
            print("Failed to start recording: \(error)")
            audioEngine = nil
            audioFile = nil
        }
    }
    
    func stopRecording() -> Data? {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        audioFile = nil
        
        guard let outputURL = outputURL else { return nil }
        return try? Data(contentsOf: outputURL)
    }
}
