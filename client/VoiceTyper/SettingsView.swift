import SwiftUI

struct SettingsView: View {
    @AppStorage("serverHost") private var serverHost = "127.0.0.1"
    @AppStorage("serverPort") private var serverPort = "9001"
    @AppStorage("whisperModel") private var whisperModel = WhisperModelSize.small.rawValue
    @AppStorage("cleanWithLLM") private var cleanWithLLM = true
    @AppStorage("language") private var language = TranscriptionLanguage.auto.rawValue
    
    var body: some View {
        TabView {
            Form {
                Section("Сервер") {
                    HStack {
                        Text("Хост:")
                        TextField("IP адрес", text: $serverHost)
                    }
                    HStack {
                        Text("Порт:")
                        TextField("Порт", text: $serverPort)
                            .frame(width: 80)
                    }
                }
                
                Section("Модели") {
                    Picker("Whisper", selection: $whisperModel) {
                        ForEach(WhisperModelSize.allCases, id: \.rawValue) { model in
                            Text(model.displayName).tag(model.rawValue)
                        }
                    }
                    
                    Toggle("Чистка в LLM", isOn: $cleanWithLLM)
                }
                
                Section("Язык") {
                    Picker("Язык", selection: $language) {
                        ForEach(TranscriptionLanguage.allCases, id: \.rawValue) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                }
            }
            .padding()
            .tabItem { Label("Основные", systemImage: "gear") }
        }
        .frame(width: 400, height: 300)
    }
}
