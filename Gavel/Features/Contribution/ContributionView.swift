import SwiftUI

/// 記録（貢献）画面。ウォレットの代わりに「100件ゴールへの進捗・ミッション別内訳・投稿履歴」を見せる。
struct ContributionView: View {
    @Environment(AppContainer.self) private var container
    @State private var model: ContributionViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("記録")
        }
        .task(id: container.dataVersion) {
            if model == nil {
                model = ContributionViewModel(submissionStore: container.submissionStore)
            }
            await model?.load()
        }
    }

    private func content(_ model: ContributionViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                goalCard(model)
                ContributionSummaryCard(summary: model.summary)

                Text("v1 は固定謝礼＋この貢献記録での運用です。売上に応じた継続還元（レベニューシェア）は公開フェーズで提供します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !model.missionBreakdown.isEmpty {
                    missionBreakdown(model)
                }

                if model.submissions.isEmpty {
                    ContentUnavailableView(
                        "まだ投稿がありません",
                        systemImage: "tray",
                        description: Text("ミッションを選んで、最初の1件を撮影してみましょう。")
                    )
                    .padding(.top, 40)
                } else {
                    Text("投稿履歴")
                        .font(.headline)
                    VStack(spacing: 10) {
                        ForEach(model.submissions) { submission in
                            NavigationLink {
                                SubmissionDetailView(submission: submission, model: model)
                            } label: {
                                submissionRow(model, submission)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func goalCard(_ model: ContributionViewModel) -> some View {
        let remaining = max(0, ContributionViewModel.sampleGoal - model.summary.total)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("100件ゴール")
                    .font(.headline)
                Spacer()
                Text("\(model.summary.total) / \(ContributionViewModel.sampleGoal)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: model.goalProgress)
                .tint(GavelTheme.sage)
            Text(remaining > 0 ? "買い手に持ち込む高品質サンプルまであと\(remaining)件。" : "目標達成！引き続き質の高い実演を集めましょう。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func missionBreakdown(_ model: ContributionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ミッション別")
                .font(.headline)
            ForEach(model.missionBreakdown) { row in
                HStack {
                    Text(row.title)
                        .font(.subheadline)
                    Spacer()
                    Text("\(row.count)件")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func submissionRow(_ model: ContributionViewModel, _ submission: Submission) -> some View {
        HStack(spacing: 12) {
            Image(systemName: submission.outcome == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(submission.outcome == .success ? GavelTheme.success : GavelTheme.momiji)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.missionTitle(for: submission))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Text(submission.createdAt, format: .dateTime.month().day().hour().minute())
                    if submission.hasAudioAnnotation {
                        Label("音声", systemImage: "mic").labelStyle(.titleAndIcon)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
