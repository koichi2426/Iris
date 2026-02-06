import Foundation
import Combine
import WatchConnectivity
import Speech
import AVFoundation

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
}

class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnector()
    var session: WCSession
    
    @Published var logs: [LogEntry] = []
    @Published var transcribedText: String = "" // 最新の文字起こし結果
    
    @Published var serverURL: String = UserDefaults.standard.string(forKey: "server_url") ?? "https://your-api-endpoint.com" {
        didSet { UserDefaults.standard.set(serverURL, forKey: "server_url") }
    }

    // --- 音声認識用プロパティ ---
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Watchの入力形式に合わせたフォーマット (通常 44.1kHz Mono Float)
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        setupSpeech()
        if WCSession.isSupported() {
            self.session.delegate = self
            self.session.activate()
        }
    }
    
    private func setupSpeech() {
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech Recognition Auth: \(status)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // 1. 音声データの処理
            if let audioData = message["audio_chunk"] as? Data {
                self.handleAudioChunk(audioData)
            }
            
            // 2. 心拍数などのメタデータの処理
            if let heartRate = message["heartRate"] as? Double {
                self.addLog("💓 HeartRate: \(Int(heartRate)) BPM")
            }
            
            // サーバーへの転送は継続
            self.relayToServer(payload: message)
        }
    }

    private func handleAudioChunk(_ data: Data) {
        // 初回、または停止していたらリクエストを開始
        if recognitionRequest == nil {
            startRecognition()
        }
        
        // DataをAVAudioPCMBufferに変換してリクエストに追加
        if let buffer = dataToPCMBuffer(data: data) {
            recognitionRequest?.append(buffer)
        }
    }

    private func startRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                self.addLog("🗣️ Thinking: \(self.transcribedText)")
                
                // 確定したテキストもサーバーへ送るように拡張可能
                if result.isFinal {
                    self.relayToServer(payload: ["final_text": self.transcribedText])
                    self.recognitionRequest = nil // 次の塊のためにリセット
                }
            }
            if error != nil {
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
    }

    // DataをPCMバッファに変換する魔法の関数
    private func dataToPCMBuffer(data: Data) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(data.count) / UInt32(MemoryLayout<Float>.size)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        
        buffer.frameLength = frameCount
        data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            if let ptr = rawBufferPointer.baseAddress?.assumingMemoryBound(to: Float.self) {
                buffer.floatChannelData?[0].update(from: ptr, count: Int(frameCount))
            }
        }
        return buffer
    }

    private func addLog(_ message: String) {
        let newLog = LogEntry(timestamp: Date(), message: message)
        self.logs.insert(newLog, at: 0)
        if self.logs.count > 100 { self.logs.removeLast() }
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
