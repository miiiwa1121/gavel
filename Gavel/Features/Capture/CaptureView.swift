import SwiftUI

/// 撮影のルート。サービス（カメラ/IMU/音声）と VM を組み立て、段階に応じて画面を切り替える。
struct CaptureView: View {
    let mission: Mission

    @Environment(AppContainer.self) private var container
    @Environment(SessionModel.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var camera: AVCameraCaptureService?
    @State private var model: CaptureViewModel?

    var body: some View {
        Group {
            if let model, let camera {
                CaptureFlowView(model: model, camera: camera, onFinished: { dismiss() })
            } else {
                ProgressView("準備中…")
                    .task { await setup() }
            }
        }
        .navigationTitle("撮影")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func setup() async {
        guard model == nil, let contributor = session.contributor else { return }
        let cameraService = AVCameraCaptureService()
        let viewModel = CaptureViewModel(
            mission: mission,
            contributor: contributor,
            device: DeviceInfoProvider.current(),
            camera: cameraService,
            motion: CoreMotionRecordingService(),
            audio: AVAudioAnnotationRecorder(),
            submissionStore: container.submissionStore,
            onSaved: { [container] in container.bumpDataVersion() }
        )
        camera = cameraService
        model = viewModel
        await viewModel.prepare()
    }
}

/// 段階ごとの表示を束ねる本体。
private struct CaptureFlowView: View {
    @Bindable var model: CaptureViewModel
    let camera: AVCameraCaptureService
    let onFinished: () -> Void

    var body: some View {
        content
            .onChange(of: model.stage) { _, newValue in
                if newValue == .done { onFinished() }
            }
            .onDisappear { model.discardPending() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.stage {
        case .precheck:
            PrecheckStageView(model: model, camera: camera)
        case .recording:
            RecordingStageView(model: model, camera: camera)
        case .review, .saving:
            CaptureReviewView(model: model)
        case .done:
            ProgressView()
        case .failed(let message):
            CaptureFailureView(message: message) { model.retake() }
        }
    }
}

// MARK: - 撮影前チェック（ポカヨケ第1段）

private struct PrecheckStageView: View {
    @Bindable var model: CaptureViewModel
    let camera: AVCameraCaptureService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                viewfinder

                Text("撮影前チェック")
                    .font(.title3.bold())

                Toggle("スマホをマウントに装着した", isOn: $model.mountConfirmed)
                Toggle("手元が画面の中央に入っている", isOn: $model.handsConfirmed)

                ForEach(model.precaptureStatus.items) { item in
                    if item.kind == .brightness || item.kind == .motion {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.satisfied ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .foregroundStyle(item.satisfied ? GavelTheme.success : GavelTheme.momiji)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.kind.label).font(.subheadline.bold())
                                Text(item.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button("明るさを再測定") {
                    Task { await model.refreshBrightness() }
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await model.startRecording() }
                } label: {
                    Text("撮影を開始")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canStart)
            }
            .padding(20)
            .tint(GavelTheme.indigo)
        }
    }

    @ViewBuilder
    private var viewfinder: some View {
        switch model.cameraAvailability {
        case .available:
            CameraPreviewView(session: camera.session)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        case .unavailableNoCamera:
            unavailableBox("この端末（またはシミュレータ）ではカメラを利用できません。実機で撮影してください。")
        case .unauthorized:
            unavailableBox("カメラへのアクセスが許可されていません。設定から許可してください。")
        }
    }

    private func unavailableBox(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "video.slash")
                .font(.largeTitle)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.secondary)
        .padding(.bottom, 4)
    }
}

// MARK: - 撮影中（ポカヨケ第2段：経過時間・上限尺で自動停止）

private struct RecordingStageView: View {
    @Bindable var model: CaptureViewModel
    let camera: AVCameraCaptureService

    var body: some View {
        VStack(spacing: 16) {
            if model.cameraAvailability == .available {
                CameraPreviewView(session: camera.session)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topLeading) { recBadge.padding(12) }
            }

            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let elapsed = model.recordingStartedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
                VStack(spacing: 6) {
                    Text(String(format: "%.1f 秒 / 最大 %.0f 秒", elapsed, model.mission.maxClipDurationSec))
                        .font(.title3.monospacedDigit())
                    ProgressView(value: min(elapsed, model.mission.maxClipDurationSec), total: model.mission.maxClipDurationSec)
                        .tint(GavelTheme.momiji)
                }
            }

            Button {
                Task { await model.stopRecording() }
            } label: {
                Label("撮影を停止", systemImage: "stop.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(GavelTheme.momiji)
            .disabled(model.isStopping)
        }
        .padding(20)
        .task {
            // 上限尺での自動停止（撮影中ガイドの一部）。
            while !Task.isCancelled, model.stage == .recording {
                if model.hasReachedMaxDuration(at: Date()) {
                    await model.stopRecording()
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    private var recBadge: some View {
        Label("REC", systemImage: "circle.fill")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(GavelTheme.momiji, in: Capsule())
    }
}

// MARK: - 失敗

private struct CaptureFailureView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(GavelTheme.momiji)
            Text(message)
                .multilineTextAlignment(.center)
            Button("もう一度", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(GavelTheme.indigo)
        }
        .padding(28)
    }
}
