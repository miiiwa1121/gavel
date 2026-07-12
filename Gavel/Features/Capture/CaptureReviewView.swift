import SwiftUI
import AVKit

/// 撮影後のレビュー（ポカヨケ第3段）。品質確認・自己申告・任意音声・**プライバシー確認（必須）**・投稿。
struct CaptureReviewView: View {
    @Bindable var model: CaptureViewModel
    @State private var player: AVPlayer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                preview
                qualitySection
                outcomeSection
                if model.mission.allowsAudioAnnotation {
                    audioSection
                }
                noteSection
                privacySection

                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(GavelTheme.momiji)
                }

                actions
            }
            .padding(20)
        }
        .onAppear {
            if let recorded = model.recorded, player == nil {
                player = AVPlayer(url: recorded.url)
            }
        }
    }

    // MARK: - セクション

    @ViewBuilder
    private var preview: some View {
        if let player {
            VideoPlayer(player: player)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.secondary.opacity(0.12))
                .frame(height: 220)
                .overlay { Image(systemName: "film").font(.largeTitle).foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder
    private var qualitySection: some View {
        if let report = model.qualityReport {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    report.passed ? "品質チェックに合格しました" : "品質に注意点があります",
                    systemImage: report.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                )
                .font(.subheadline.bold())
                .foregroundStyle(report.passed ? GavelTheme.success : GavelTheme.momiji)

                ForEach(report.checks) { check in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: check.passed ? "checkmark.circle" : "xmark.circle")
                            .foregroundStyle(check.passed ? GavelTheme.success : GavelTheme.momiji)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(check.kind.displayName).font(.caption.bold())
                            Text(check.detail).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                if !report.passed {
                    Text("気になる場合は撮り直しをおすすめします。失敗の実演として残す場合は、下で「失敗」を選んで投稿してください。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("この実演の結果").font(.headline)
            Picker("結果", selection: $model.outcome) {
                ForEach(SelfReportedOutcome.allCases, id: \.self) { outcome in
                    Text(outcome.displayName).tag(outcome)
                }
            }
            .pickerStyle(.segmented)
            Text("失敗も「なぜ失敗したか」の文脈として価値があります。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("音声アノテーション（任意）").font(.headline)
            Text("「なぜそうしたか」の判断を声で添えると、より価値が高まります。")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    Task { await model.toggleAudioAnnotation() }
                } label: {
                    Label(
                        model.isRecordingAudio ? "録音を停止" : "録音する",
                        systemImage: model.isRecordingAudio ? "stop.circle.fill" : "mic.circle.fill"
                    )
                }
                .buttonStyle(.bordered)
                .tint(model.isRecordingAudio ? GavelTheme.momiji : GavelTheme.indigo)

                if model.audioAnnotationURL != nil {
                    Label("録音済み", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(GavelTheme.success)
                    Button("削除") { model.clearAudioAnnotation() }
                        .buttonStyle(.borderless)
                }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ（任意）").font(.headline)
            TextField("撮影時の状況などがあれば", text: $model.note, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $model.privacyConfirmed) {
                Text("第三者・自宅・住所が特定できる写り込みがないか確認しました（必須）")
                    .font(.subheadline)
            }
            .tint(GavelTheme.indigo)
        }
        .padding(14)
        .background(GavelTheme.momiji.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task { await model.submit() }
            } label: {
                Group {
                    if model.stage == .saving {
                        ProgressView()
                    } else {
                        Text("この内容で投稿する").frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(GavelTheme.indigo)
            .disabled(!model.canSubmit)

            Button("撮り直す") { model.retake() }
                .buttonStyle(.bordered)
                .disabled(model.stage == .saving)
        }
    }
}
