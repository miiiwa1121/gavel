import SwiftUI

extension MissionCategory {
    /// カテゴリを表す SF Symbol。
    var symbolName: String {
        switch self {
        case .cooking: "frying.pan"
        case .tableware: "fork.knife"
        case .housework: "house"
        case .other: "square.grid.2x2"
        }
    }
}

/// 貢献記録サマリのカード（ウォレット代替）。
struct ContributionSummaryCard: View {
    let summary: ContributionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("これまでの貢献")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 0) {
                stat(value: summary.total, label: "投稿", systemImage: "square.stack.3d.up.fill")
                divider
                stat(value: summary.successCount, label: "成功", systemImage: "checkmark.circle.fill")
                divider
                stat(value: summary.withAudioAnnotationCount, label: "音声付き", systemImage: "mic.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GavelTheme.indigo, in: RoundedRectangle(cornerRadius: 18))
    }

    private func stat(value: Int, label: String, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(.white.opacity(0.9))
            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.2))
            .frame(width: 1, height: 40)
    }
}

/// ミッション一覧の 1 行。
struct MissionRow: View {
    let mission: Mission

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: mission.category.symbolName)
                .font(.title3)
                .foregroundStyle(GavelTheme.indigo)
                .frame(width: 44, height: 44)
                .background(GavelTheme.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(mission.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
