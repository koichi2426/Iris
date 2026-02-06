// Iris/PhoneConnector.swift
import Foundation
import Combine
import WatchConnectivity

// ログ1件分のデータ構造
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
}

class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnector()
    var session: WCSession
    
    // ログの履歴を保持する配列
    @Published var logs: [LogEntry] = []
    
    @Published var serverURL: String = UserDefaults.standard.string(forKey: "server_url") ?? "https://your-api-endpoint.com" {
        didSet { UserDefaults.standard.set(serverURL, forKey: "server_url") }
    }

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        if WCSession.isSupported() {
            self.session.delegate = self
            self.session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // 新しいログを作成
            let keys = message.keys.joined(separator: ", ")
            let newLog = LogEntry(timestamp: Date(), message: "📩 Relayed: [\(keys)]")
            
            // 配列の先頭に追加（最大100件）
            self.logs.insert(newLog, at: 0)
            if self.logs.count > 100 { self.logs.removeLast() }
            
            self.relayToServer(payload: message)
        }
    }

    private func relayToServer(payload: [String: Any]) {
        guard let url = URL(string: serverURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { self.session.activate() }
    #endif
}
