import SwiftUI

@main
struct TatamiApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .task { await model.run() }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    model.setScenePhase(phase)
                }
        }
    }
}
