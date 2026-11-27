import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        Form {
            LabeledContent("Версия", value: "\(version) (\(build))")
            Text("Демонстрационная сборка: звук с микрофона не записывается, запросы на сервер не отправляются.")
            NavigationLink("Диагностика") { DiagnosticsView(model: model) }
        }
        .navigationTitle("Настройки")
    }
}

struct DiagnosticsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Состояние") {
                LabeledContent("Запись", value: model.stateText)
                LabeledContent("Приложение", value: model.sceneDescription)
                LabeledContent("Последняя ошибка", value: errorText)
            }
            Section("Очередь") {
                ForEach(JobCategory.allCases, id: \.self) { category in
                    LabeledContent(category.rawValue, value: String(model.count(category)))
                }
            }
            Text("Здесь показаны только состояния и счётчики. Текст записей и аудио в диагностику не включаются.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Диагностика")
    }

    private var errorText: String {
        switch model.lastErrorCategory {
        case "storage": return "Хранилище"
        case "permission": return "Доступ к микрофону"
        case "capture": return "Запись"
        case "transcription": return "Расшифровка"
        default: return "Нет"
        }
    }
}
