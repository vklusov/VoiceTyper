import SwiftUI

struct StatusBarView: View {
    let settings: Settings
    @State private var serverStatus: String = "Проверка..."
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("VoiceTyper")
                .font(.title2)
                .bold()
            
            Text("Option+Space — запись")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Circle()
                    .fill(serverStatus == "Готов" ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text("Сервер: \(serverStatus)")
                    .font(.caption)
            }
            
            Button("Настройки...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            
            Button("Выход") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            checkServer()
        }
    }
    
    private func checkServer() {
        let host = UserDefaults.standard.string(forKey: "serverHost") ?? "127.0.0.1"
        let port = UserDefaults.standard.string(forKey: "serverPort") ?? "9001"
        let url = URL(string: "http://\(host):\(port)/status")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   status == "ok" {
                    serverStatus = "Готов"
                } else {
                    serverStatus = "Нет связи"
                }
            }
        }.resume()
    }
}
