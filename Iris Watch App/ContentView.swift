import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject var workoutManager = WorkoutManager.shared
    
    var body: some View {
        VStack {
            Button(action: {
                if workoutManager.isRunning {
                    workoutManager.stopZombieMode()
                } else {
                    workoutManager.startZombieMode()
                }
            }) {
                // 状態によって色が変わる目のアイコン
                Image(systemName: workoutManager.isRunning ? "eye.fill" : "eye.slash.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(workoutManager.isRunning ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // デフォルトのボタン枠を消す
            
            Text(workoutManager.isRunning ? "System Active" : "Sleeping")
                .font(.headline)
                .padding(.top, 10)
                .foregroundColor(workoutManager.isRunning ? .green : .gray)
        }
        .onAppear {
            // アプリ起動時に権限をリクエスト
            workoutManager.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
