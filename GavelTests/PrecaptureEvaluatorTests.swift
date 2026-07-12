import Testing
@testable import Gavel

struct PrecaptureEvaluatorTests {
    @Test
    func allSatisfiedAllowsStart() {
        let status = PrecaptureEvaluator.evaluate(
            mountConfirmed: true, handsConfirmed: true, brightness: 0.5, motionAvailable: true)
        #expect(status.canStart)
    }

    @Test
    func missingMountBlocksStart() {
        let status = PrecaptureEvaluator.evaluate(
            mountConfirmed: false, handsConfirmed: true, brightness: 0.5, motionAvailable: true)
        #expect(!status.canStart)
    }

    @Test
    func missingMotionBlocksStart() {
        let status = PrecaptureEvaluator.evaluate(
            mountConfirmed: true, handsConfirmed: true, brightness: 0.5, motionAvailable: false)
        #expect(!status.canStart)
    }

    @Test
    func darkBrightnessBlocksStart() {
        let status = PrecaptureEvaluator.evaluate(
            mountConfirmed: true, handsConfirmed: true, brightness: 0.01, motionAvailable: true)
        #expect(!status.canStart)
    }

    @Test
    func nilBrightnessBlocksStart() {
        let status = PrecaptureEvaluator.evaluate(
            mountConfirmed: true, handsConfirmed: true, brightness: nil, motionAvailable: true)
        #expect(!status.canStart)
    }

    @Test
    func evaluatesAllFourItems() {
        let status = PrecaptureEvaluator.evaluate(
            mountConfirmed: true, handsConfirmed: true, brightness: 0.5, motionAvailable: true)
        #expect(status.items.count == PrecaptureItemKind.allCases.count)
    }
}

struct CaptureTimingTests {
    @Test
    func stopsAtOrAfterMax() {
        #expect(CaptureTiming.shouldAutoStop(elapsedSec: 60, maxDurationSec: 60))
        #expect(CaptureTiming.shouldAutoStop(elapsedSec: 61, maxDurationSec: 60))
    }

    @Test
    func doesNotStopBeforeMax() {
        #expect(!CaptureTiming.shouldAutoStop(elapsedSec: 59.9, maxDurationSec: 60))
    }
}
