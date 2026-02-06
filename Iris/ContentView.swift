// Iris/ContentView.swift (iOS)
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject var connector = PhoneConnector.shared
    
    // ダークモード用のカラー設定
    let backgroundColor = Color.black
    let accentColor = Color.green // ゾンビモードの目玉と合わせた緑
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 設定セクション
                Form {
                    Section {
                        HStack {
                            Circle()
                                .fill(connector.session.isReachable ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(connector.session.isReachable ? "SYNAPSE: ACTIVE" : "SYNAPSE: OFFLINE")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("BRAIN ENDPOINT URL")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                            TextField("https://...", text: $connector.serverURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(accentColor)
                        }
                    } header: {
                        Text("GATEWAY CONFIG")
                    }
                }
                .frame(height: 180)
                .scrollContentBackground(.hidden) // 標準の背景を消す
                .background(backgroundColor)
                
                Divider().background(Color.gray)
                
                // 2. リアルタイムログセクション
                ZStack(alignment: .topLeading) {
                    backgroundColor.edgesIgnoringSafeArea(.all)
                    
                    VStack(alignment: .leading) {
                        Text("LIVE STREAM DATA")
                            .font(.system(size: 12, design: .monospaced))
                            .padding([.leading, .top], 16)
                            .foregroundColor(.gray)
                        
                        List(connector.logs) { log in
                            HStack(alignment: .top, spacing: 10) {
                                Text(log.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text(log.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .listRowBackground(backgroundColor)
                            .listRowSeparator(.visible, edges: .bottom)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("IRIS GATEWAY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark) // 常にダークモードを強制
    }
}
