import SwiftUI
import UIKit
import TatamiCore

struct HistoryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            if model.jobs.isEmpty {
                ContentUnavailableView("Записей пока нет", systemImage: "waveform",
                                       description: Text("Сделайте демонстрационную запись на первой вкладке."))
            }
            ForEach(model.jobs) { job in
                VStack(alignment: .leading, spacing: 10) {
                    Text(job.recording.createdAt, format: .dateTime.day().month().hour().minute())
                        .font(.headline)
                    Text("\(JobCategory(state: job.state).rawValue) · \(durationText(job.recording.duration))")
                        .font(.caption).foregroundStyle(.secondary)
                    if case .transcribed(let text) = job.state {
                        Text(text).textSelection(.enabled)
                        HStack(spacing: 24) {
                            Button {
                                UIPasteboard.general.string = text
                            } label: {
                                Label("Копировать", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            ShareLink(item: text) { Label("Поделиться", systemImage: "square.and.arrow.up") }
                                .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("История")
    }
}
