import Foundation
import Combine  // ← これを追加！
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnector()
    var session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        self.session.activate()
    }
    
    func sendTestMessage() {
        if session.isReachable {
            let message = ["text": "Hello iPhone! This is Watch via Synapse."]
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
            print("📤 Sent message to iPhone")
        } else {
            print("⚠️ iPhone is not reachable")
        }
    }
    
    // WCSessionDelegate 必須メソッド
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error { print("Session activation failed: \(error.localizedDescription)") }
    }
}
