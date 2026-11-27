import SwiftUI
import TatamiCore

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            NavigationStack { RecordView(model: model) }
                .tabItem {
                    Label("Запись", systemImage: "mic.fill").accessibilityIdentifier("tab.record")
                }
            NavigationStack { HistoryView(model: model) }
                .tabItem {
                    Label("История", systemImage: "clock").accessibilityIdentifier("tab.history")
                }
            NavigationStack { SettingsView(model: model) }
                .tabItem {
                    Label("Настройки", systemImage: "gearshape").accessibilityIdentifier("tab.settings")
                }
        }
    }
}

private struct RecordView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 28) {
            Text("Демо: микрофон и сервер заменены имитацией.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Text(model.stateText).font(.title2).multilineTextAlignment(.center)
            Text(durationText(model.elapsed))
                .font(.system(size: 48, design: .monospaced))
                .accessibilityLabel("Длительность \(Int(model.elapsed)) секунд")
            Button {
                Task { await model.toggleRecording() }
            } label: {
                Label(model.recordButtonTitle, systemImage: model.machine.state == .recording ? "stop.fill" : "mic.fill")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canToggle)
            .accessibilityIdentifier("record.toggle")
            if model.lastErrorCategory != nil {
                Text("Возникла ошибка. Данные не удалены. Подробности — в диагностике.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Запись")
    }
}

func durationText(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%02d:%02d", total / 60, total % 60)
}
