import SwiftUI
import AVKit

/// 投稿の詳細。撮った映像の再生・メタ情報・削除（確認つき）。
struct SubmissionDetailView: View {
    let submission: Submission
    let model: ContributionViewModel

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var mediaResolved = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                if let player {
                    VideoPlayer(player: player)
                        .frame(height: 240)
                        .listRowInsets(EdgeInsets())
                } else if mediaResolved {
                    unavailableMedia
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }

            Section("この投稿") {
                LabeledContent("ミッション", value: model.missionTitle(for: submission))
                LabeledContent("結果", value: submission.outcome.displayName)
                LabeledContent("撮影日時") {
                    Text(submission.createdAt, format: .dateTime.year().month().day().hour().minute())
                }
                LabeledContent("長さ", value: String(format: "%.1f秒", submission.videoDurationSec))
                LabeledContent("解像度", value: "\(submission.videoResolution.width)×\(submission.videoResolution.height)")
                LabeledContent("IMU", value: "\(submission.imuSampleCount)サンプル / \(Int(submission.imuSampleRateHz))Hz")
                LabeledContent("音声アノテ", value: submission.hasAudioAnnotation ? "あり" : "なし")
                LabeledContent("プライバシー確認", value: submission.privacyConfirmed ? "確認済" : "未確認")
                LabeledContent("同期状態", value: submission.syncState.displayName)
                if let note = submission.note, !note.isEmpty {
                    LabeledContent("メモ", value: note)
                }
            }

            Section {
                Button("この投稿を削除", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("投稿の詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let media = await model.media(for: submission) {
                player = AVPlayer(url: media.video)
            }
            mediaResolved = true
        }
        .confirmationDialog("この投稿を削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                Task {
                    await model.delete(submission)
                    container.bumpDataVersion()
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private var unavailableMedia: some View {
        HStack {
            Image(systemName: "film.slash")
            Text("映像を読み込めませんでした")
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}
