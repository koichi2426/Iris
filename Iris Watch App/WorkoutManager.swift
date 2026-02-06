import Foundation
import Combine
import HealthKit
import AVFoundation

class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var isRunning = false
    @Published var heartRate: Double = 0
    
    private let audioEngine = AVAudioEngine()
    
    func requestAuthorization() {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            if success {
                AVAudioApplication.requestRecordPermission { granted in
                    print("Microphone Permission: \(granted)")
                }
            }
        }
    }
    
    func startZombieMode() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            session?.delegate = self
            builder?.delegate = self
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { _, _ in }
            
            try startStreamingAudio()
            
            DispatchQueue.main.async { self.isRunning = true }
        } catch {
            print("Failed: \(error.localizedDescription)")
        }
    }
    
    private func startStreamingAudio() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            let audioData = self.audioBufferToData(buffer: buffer)
            // ここで呼ぶ sendData は下の WatchConnector で定義します
            WatchConnector.shared.sendData(["audio_chunk": audioData])
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func audioBufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let frameLength = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData else { return Data() }
        let channels = UnsafeBufferPointer(start: channelData, count: Int(buffer.format.channelCount))
        // ! を使わず安全にコピー
        let data = Data(bytes: channels[0], count: frameLength * MemoryLayout<Float>.size)
        return data
    }
    
    func stopZombieMode() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        DispatchQueue.main.async { self.isRunning = false }
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            // [修正済] Type 'String' has no member 'heartRate' を防ぐ正しい比較
            if quantityType == HKObjectType.quantityType(forIdentifier: .heartRate) {
                let statistics = workoutBuilder.statistics(for: quantityType)
                let value = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                
                DispatchQueue.main.async {
                    self.heartRate = value
                    WatchConnector.shared.sendData(["heartRate": value])
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
