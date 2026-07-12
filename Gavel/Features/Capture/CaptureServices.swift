import Foundation

/// 撮影まわりの定数。
enum CaptureConfig {
    /// IMU の公称サンプリングレート（Hz）。中核設計A の時刻同期の前提。
    static let imuSampleRateHz: Double = 100
}

/// カメラの利用可否。シミュレータにはカメラが無いため `unavailableNoCamera` を明示的に扱う。
enum CameraAvailability: Equatable, Sendable {
    case available
    case unauthorized
    case unavailableNoCamera
}

/// 収録済み映像の結果（品質判定に必要な数値を含む）。
struct RecordedVideo: Sendable, Equatable {
    var url: URL
    var durationSec: Double
    var resolution: Resolution
    /// ピント（鮮鋭度）指標。
    var sharpness: Double
    /// 平均輝度（0..1）。
    var brightness: Double
}

/// カメラ収録サービス（実装は AVFoundation・実機のみ）。テストは fake を注入する。
protocol CameraCaptureService: Sendable {
    /// 権限確認・セッション構成を行い、利用可否を返す。
    func prepare() async -> CameraAvailability
    /// ライブ映像から平均輝度（0..1）を推定する。取得不能なら nil。
    func sampleBrightness() async -> Double?
    /// 収録を開始する。
    func startRecording() async throws
    /// 収録を停止し、結果を返す。
    func stopRecording() async throws -> RecordedVideo
}

/// IMU 収録サービス（実装は CoreMotion）。テストは fake を注入する。
protocol MotionRecordingService: Sendable {
    /// deviceMotion が利用可能か。
    func isAvailable() async -> Bool
    /// 収録開始（この時点を相対時刻 t=0 とする）。
    func start() async
    /// 停止して蓄積した IMU サンプルを返す。
    func stop() async -> [IMUSample]
}

/// 音声アノテーション録音サービス（任意・後付け型）。実装は AVAudioRecorder。
protocol AudioAnnotationRecording: Sendable {
    /// 録音を開始する。
    func startRecording() async throws
    /// 録音を停止し、録音ファイルの URL を返す。
    func stopRecording() async throws -> URL
}
