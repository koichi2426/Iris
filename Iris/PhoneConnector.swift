import Foundation
import Combine  // ← これを追加！
import WatchConnectivity

class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnector()
    var session: WCSession
    
    @Published var receivedLog: String = "No Signal yet..."
    
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
            if let text = message["text"] as? String {
                self.receivedLog = "📩 Received:\n\(text)\n(\(Date()))"
                print(self.receivedLog)
            }
        }
    }
    
    // WCSessionDelegate 必須メソッド
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
