import Foundation
import WatchConnectivity

class WatchConnector: NSObject, WCSessionDelegate {
    static let shared = WatchConnector()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendData(_ data: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil) { error in
                print("Send Error: \(error.localizedDescription)")
            }
        } else {
            // iPhoneがスリープ中の場合はバックグラウンドで同期
            try? WCSession.default.updateApplicationContext(data)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
