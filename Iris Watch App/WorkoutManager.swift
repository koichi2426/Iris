import Foundation
import Combine  // ← これを追加しました！これでエラーが消えます
import HealthKit

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    // UIの表示切り替え用
    @Published var isRunning = false
    
    static let shared = WorkoutManager()
    
    // 権限リクエスト
    func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // 心拍数などを読み取る権限
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("Auth Error: \(error.localizedDescription)")
            }
        }
    }
    
    // ゾンビ化開始（ワークアウトセッション開始）
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
            builder?.beginCollection(withStart: startDate) { (success, error) in
                if success {
                    print("💪 Builder collection started")
                }
            }
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
            print("👁️ Zombie Mode (Session) Started")
            
        } catch {
            print("Failed to start session: \(error.localizedDescription)")
        }
    }
    
    // 停止処理
    func stopZombieMode() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            self.builder?.finishWorkout { (workout, error) in
                print("Workout finished")
            }
        }
        
        session = nil
        builder = nil
        
        DispatchQueue.main.async {
            self.isRunning = false
        }
        print("Zombie Mode Stopped")
    }
}

// 必須デリゲート（OSからの通知を受け取る）
extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .running {
            print("Session status: Running")
        } else if toState == .ended {
            print("Session status: Ended")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Session error: \(error.localizedDescription)")
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // データが来るたびに呼ばれる
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
