import Foundation

struct TranscriptionResult: Codable {
    let raw: String
    let cleaned: String?
    let language: String
    let language_probability: Double
    let duration_ms: Int
    let model: String
}

class VoiceTyperClient: @unchecked Sendable {
    private var baseURL: String {
        let host = UserDefaults.standard.string(forKey: "serverHost") ?? "127.0.0.1"
        let port = UserDefaults.standard.string(forKey: "serverPort") ?? "9001"
        return "http://\(host):\(port)"
    }
    
    func transcribe(audioData: Data, cleanWithLLM: Bool, language: String) async throws -> TranscriptionResult {
        let url = URL(string: "\(baseURL)/transcribe")!
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()
        
        // Audio file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // clean_llm part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"clean_llm\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cleanWithLLM)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // language part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append(language.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // End
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(TranscriptionResult.self, from: data)
    }
}
