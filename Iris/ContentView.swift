import SwiftUI

struct ContentView: View {
    // PhoneConnectorを使う準備
    @StateObject var connector = PhoneConnector.shared
    
    var body: some View {
        VStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Iris Gateway")
                .font(.largeTitle)
                .bold()
            
            Divider().padding()
            
            Text("Last Signal:")
                .font(.caption)
                .foregroundColor(.gray)
            
            // 受信したメッセージを表示する場所
            Text(connector.receivedLog)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
        }
    }
}
