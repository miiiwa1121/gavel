import Foundation
import Testing
@testable import Gavel

struct SubmissionManifestTests {
    private func sampleSubmission() -> Submission {
        Submission(
            missionId: "chopsticks-plating",
            contributorId: UUID(),
            // ISO8601（既定）は小数秒を持たないため、往復一致を見るテストでは秒単位の固定日時を使う。
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            outcome: .success,
            mountType: .chest,
            device: DeviceInfo(model: "iPhone16,1", systemVersion: "18.0"),
            videoDurationSec: 12.5,
            videoResolution: Resolution(width: 1920, height: 1080),
            imuSampleCount: 1250,
            imuSampleRateHz: 100,
            hasAudioAnnotation: true,
            privacyConfirmed: true
        )
    }

    @Test
    func manifestRoundTrips() throws {
        let manifest = SubmissionManifest(
            submission: sampleSubmission(),
            files: SubmissionFileRefs(video: "video.mov", imu: "imu.jsonl", audioAnnotation: "annotation.m4a")
        )
        let data = try GavelJSON.makeEncoder().encode(manifest)
        let decoded = try GavelJSON.makeDecoder().decode(SubmissionManifest.self, from: data)
        #expect(decoded == manifest)
        #expect(decoded.schemaVersion == SubmissionManifest.currentSchemaVersion)
    }

    @Test
    func defaultSyncStateIsPending() {
        // v1 は実サーバ送信を行わないため既定は pendingSync。
        #expect(sampleSubmission().syncState == .pendingSync)
    }
}
