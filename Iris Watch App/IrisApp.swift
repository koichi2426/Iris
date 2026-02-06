import SwiftUI

@main
struct Iris_Watch_AppApp: App {
    init() {
        _ = WatchConnector.shared
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
