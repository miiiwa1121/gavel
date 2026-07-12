import SwiftUI

/// ミッション詳細。タスク説明・お手本・成功条件・撮り方の注意を示し、撮影へ導く。
struct MissionDetailView: View {
    let mission: Mission

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                section(title: "このタスクについて") {
                    Text(mission.taskDescription)
                        .font(.callout)
                }
                section(title: "お手本・望ましいやり方") {
                    Text(mission.exampleGuidance)
                        .font(.callout)
                }
                bulletSection(title: "成功条件", items: mission.successConditions, symbol: "checkmark.circle")
                bulletSection(title: "撮り方の注意", items: mission.shootingTips, symbol: "camera")

                if mission.allowsAudioAnnotation {
                    Label("「なぜそうしたか」を音声で添えると、より価値が高まります（任意）。", systemImage: "mic")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                CaptureView(mission: mission)
            } label: {
                Text("このミッションで撮影する")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
            .background(.bar)
        }
        .navigationTitle(mission.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: mission.category.symbolName)
                    .font(.title2)
                    .foregroundStyle(GavelTheme.indigo)
                Text(mission.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if mission.isJapanSpecific {
                    Text("日本特有")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GavelTheme.momiji.opacity(0.15), in: Capsule())
                        .foregroundStyle(GavelTheme.momiji)
                }
            }
            Text(mission.title)
                .font(.title.bold())
            Label(
                String(format: "撮影時間の目安：%.0f〜%.0f秒", mission.minClipDurationSec, mission.maxClipDurationSec),
                systemImage: "clock"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            Label("推奨マウント：\(mission.recommendedMountType.displayName)", systemImage: "iphone")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
    }

    private func bulletSection(title: String, items: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Label {
                    Text(item).font(.callout)
                } icon: {
                    Image(systemName: symbol).foregroundStyle(GavelTheme.sage)
                }
            }
        }
    }
}
