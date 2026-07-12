import SwiftUI

/// ホーム。あいさつ・貢献サマリ・常設ミッションへの入口。
struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(SessionModel.self) private var session
    @State private var model: HomeViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("ホーム")
        }
        .task(id: container.dataVersion) {
            if model == nil {
                model = HomeViewModel(submissionStore: container.submissionStore)
            }
            await model?.load()
        }
    }

    private func content(_ model: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("おかえりなさい")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(session.contributor?.displayName ?? "協力者")さん")
                        .font(.title.bold())
                    Text("今日も1つ、手元の動作を撮って残しましょう。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                ContributionSummaryCard(summary: model.summary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ミッション")
                        .font(.headline)
                    Text("日本特有の手元動作を集めています。1つ選んで撮影しましょう。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach(model.missions) { mission in
                        NavigationLink(value: mission) {
                            MissionRow(mission: mission)
                                .padding(12)
                                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .navigationDestination(for: Mission.self) { mission in
            MissionDetailView(mission: mission)
        }
    }
}
