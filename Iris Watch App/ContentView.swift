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
                Image(systemName: workoutManager.isRunning ? "eye.fill" : "eye.slash.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(workoutManager.isRunning ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(workoutManager.isRunning ? "System Active" : "Sleeping")
                .font(.headline)
                .padding(.top, 10)
                .foregroundColor(workoutManager.isRunning ? .green : .gray)
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}
