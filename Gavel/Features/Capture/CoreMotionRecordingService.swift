import Foundation
import CoreMotion

/// CoreMotion による IMU 収録。deviceMotion を公称レートでポーリングし、開始時刻を 0 とした
/// 相対時刻 `t` でサンプルを蓄積する。CMMotionManager を actor に閉じてスレッド安全にする。
actor CoreMotionRecordingService: MotionRecordingService {
    private let manager = CMMotionManager()
    private var samples: [IMUSample] = []
    private var referenceTimestamp: TimeInterval?
    private var lastTimestamp: TimeInterval?
    private var pollingTask: Task<Void, Never>?

    func isAvailable() -> Bool {
        manager.isDeviceMotionAvailable
    }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        samples.removeAll()
        // 収録開始の瞬間を t=0 のアンカーにする。systemUptime は deviceMotion.timestamp と
        // 同じ時間基準（起動からの秒）なので、センサ暖機を待たず開始時刻に相対化できる。
        referenceTimestamp = ProcessInfo.processInfo.systemUptime
        lastTimestamp = nil
        manager.deviceMotionUpdateInterval = 1.0 / CaptureConfig.imuSampleRateHz
        manager.startDeviceMotionUpdates()

        // 取りこぼしを防ぐため公称レートの2倍でポーリングし、timestamp が変わった時だけ採取。
        let intervalNanos = UInt64(1_000_000_000 / (CaptureConfig.imuSampleRateHz * 2))
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                try? await Task.sleep(nanoseconds: intervalNanos)
            }
        }
    }

    func stop() -> [IMUSample] {
        pollingTask?.cancel()
        pollingTask = nil
        manager.stopDeviceMotionUpdates()
        return samples
    }

    private func pollOnce() {
        guard let motion = manager.deviceMotion else { return }
        let timestamp = motion.timestamp
        if lastTimestamp == timestamp { return }
        lastTimestamp = timestamp

        // 開始前に届いたサンプル（t<0）はスキップし、開始時刻アンカーからの相対時刻で採取する。
        let reference = referenceTimestamp ?? timestamp
        if timestamp < reference { return }

        let quaternion = motion.attitude.quaternion
        let sample = IMUSample(
            t: timestamp - reference,
            userAcceleration: Vector3(
                x: motion.userAcceleration.x,
                y: motion.userAcceleration.y,
                z: motion.userAcceleration.z
            ),
            rotationRate: Vector3(
                x: motion.rotationRate.x,
                y: motion.rotationRate.y,
                z: motion.rotationRate.z
            ),
            gravity: Vector3(
                x: motion.gravity.x,
                y: motion.gravity.y,
                z: motion.gravity.z
            ),
            attitude: Quaternion(
                w: quaternion.w,
                x: quaternion.x,
                y: quaternion.y,
                z: quaternion.z
            )
        )
        samples.append(sample)
    }
}
