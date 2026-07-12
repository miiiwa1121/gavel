import Testing
@testable import Gavel

struct QualityEvaluatorTests {
    /// すべての基準を満たす入力。
    private func goodInput(
        resolution: Resolution = Resolution(width: 1920, height: 1080),
        duration: Double = 10,
        sharpness: Double = 40,
        brightness: Double = 0.5,
        imuCount: Int = 1000,
        rate: Double = 100
    ) -> CaptureQualityInput {
        CaptureQualityInput(
            resolution: resolution,
            durationSec: duration,
            sharpness: sharpness,
            brightness: brightness,
            imuSampleCount: imuCount,
            imuSampleRateHz: rate,
            minClipDurationSec: 3,
            maxClipDurationSec: 60
        )
    }

    /// #expect の中で rethrows 高階関数（map(\.kind) 等）を使うとマクロ展開が
    /// throw 扱いになるため、判定用のキー配列は事前に取り出しておく。
    private func failedKinds(_ report: QualityReport) -> [QualityCheckKind] {
        report.failures.map(\.kind)
    }

    @Test
    func passesWhenAllCriteriaMet() {
        let report = QualityEvaluator.evaluate(goodInput())
        #expect(report.passed)
        #expect(report.failures.isEmpty)
        // requireIMU=true の既定では 6 チェック。
        #expect(report.checks.count == 6)
    }

    @Test
    func failsOnLowResolution() {
        let report = QualityEvaluator.evaluate(goodInput(resolution: Resolution(width: 640, height: 480)))
        let kinds = failedKinds(report)
        #expect(!report.passed)
        #expect(kinds.contains(.resolution))
    }

    @Test
    func acceptsPortraitOrientation() {
        // 縦向き（長辺/短辺で判定するので 1080×1920 も合格する）。
        let report = QualityEvaluator.evaluate(goodInput(resolution: Resolution(width: 1080, height: 1920)))
        let resolutionCheck = report.checks.first { $0.kind == .resolution }
        #expect(resolutionCheck?.passed == true)
    }

    @Test
    func failsWhenTooShort() {
        let report = QualityEvaluator.evaluate(goodInput(duration: 1, imuCount: 100))
        #expect(failedKinds(report).contains(.duration))
    }

    @Test
    func failsWhenTooLong() {
        let report = QualityEvaluator.evaluate(goodInput(duration: 90, imuCount: 9000))
        #expect(failedKinds(report).contains(.duration))
    }

    @Test
    func failsOnBlur() {
        let report = QualityEvaluator.evaluate(goodInput(sharpness: 5))
        #expect(failedKinds(report).contains(.sharpness))
    }

    @Test
    func failsWhenTooDark() {
        let report = QualityEvaluator.evaluate(goodInput(brightness: 0.02))
        #expect(failedKinds(report).contains(.brightness))
    }

    @Test
    func failsWhenTooBright() {
        let report = QualityEvaluator.evaluate(goodInput(brightness: 0.99))
        #expect(failedKinds(report).contains(.brightness))
    }

    @Test
    func failsWhenIMUMissing() {
        // 映像と IMU は常にセット（中核設計Aの不変ルール）。IMU 0 件は不合格。
        let report = QualityEvaluator.evaluate(goodInput(imuCount: 0))
        #expect(!report.passed)
        #expect(failedKinds(report).contains(.imuPresence))
    }

    @Test
    func failsWhenIMUCoverageLow() {
        // 10秒×100Hz=1000期待に対し 300件（30%）はカバレッジ不足。
        let report = QualityEvaluator.evaluate(goodInput(imuCount: 300))
        #expect(failedKinds(report).contains(.imuCoverage))
    }

    // MARK: - 境界値

    @Test
    func durationBoundariesAreInclusive() {
        let atMin = QualityEvaluator.evaluate(goodInput(duration: 3, imuCount: 300))
        let atMax = QualityEvaluator.evaluate(goodInput(duration: 60, imuCount: 6000))
        #expect(!failedKinds(atMin).contains(.duration))
        #expect(!failedKinds(atMax).contains(.duration))
    }

    @Test
    func brightnessBoundariesAreInclusive() {
        let atLow = QualityEvaluator.evaluate(goodInput(brightness: 0.12))
        let atHigh = QualityEvaluator.evaluate(goodInput(brightness: 0.92))
        #expect(!failedKinds(atLow).contains(.brightness))
        #expect(!failedKinds(atHigh).contains(.brightness))
    }

    @Test
    func resolutionExactlyAtMinimumPasses() {
        let report = QualityEvaluator.evaluate(goodInput(resolution: Resolution(width: 1280, height: 720)))
        let check = report.checks.first { $0.kind == .resolution }
        #expect(check?.passed == true)
    }

    @Test
    func imuCoverageExactlyAtThresholdPasses() {
        // 10秒×100Hz=1000期待に対し 800件＝カバレッジ 0.8（しきい値ちょうど）は合格。
        let report = QualityEvaluator.evaluate(goodInput(imuCount: 800))
        let check = report.checks.first { $0.kind == .imuCoverage }
        #expect(check?.passed == true)
    }

    @Test
    func imuCoverageFailsWhenDurationZero() {
        // 尺0は期待サンプル0で判定不能→不合格側へ倒す。
        let report = QualityEvaluator.evaluate(goodInput(duration: 0, imuCount: 100))
        #expect(failedKinds(report).contains(.imuCoverage))
    }

    @Test
    func skipsIMUChecksWhenNotRequired() {
        var standard = QualityStandard.standard
        standard.requireIMU = false
        let report = QualityEvaluator.evaluate(goodInput(imuCount: 0), standard: standard)
        let kinds = report.checks.map(\.kind)
        #expect(report.passed)
        #expect(!kinds.contains(.imuPresence))
    }
}
