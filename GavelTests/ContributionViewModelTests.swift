import Foundation
import Testing
@testable import Gavel

@MainActor
struct ContributionViewModelTests {
    private func makeStore() throws -> SubmissionStore {
        SubmissionStore(rootDirectory: try TestSupport.makeTempDirectory())
    }

    @Test
    func loadReflectsSavedSubmissions() async throws {
        let store = try makeStore()
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"),
            missionId: "chopsticks-plating", outcome: .success))
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"),
            missionId: "egg-handling", outcome: .failure))

        let viewModel = ContributionViewModel(submissionStore: store)
        await viewModel.load()

        #expect(viewModel.submissions.count == 2)
        #expect(viewModel.summary.total == 2)
        #expect(viewModel.summary.successCount == 1)
        #expect(viewModel.summary.failureCount == 1)
    }

    @Test
    func missionTitleResolvesKnownAndUnknown() throws {
        let store = try makeStore()
        let viewModel = ContributionViewModel(submissionStore: store)

        let known = Submission(
            missionId: MissionCatalog.eggHandling.id,
            contributorId: UUID(), outcome: .success, mountType: .chest,
            device: DeviceInfo(model: "m", systemVersion: "18.0"),
            videoDurationSec: 5, videoResolution: Resolution(width: 1920, height: 1080),
            imuSampleCount: 500, imuSampleRateHz: 100,
            hasAudioAnnotation: false, privacyConfirmed: true)
        #expect(viewModel.missionTitle(for: known) == MissionCatalog.eggHandling.title)

        let unknown = Submission(
            missionId: "ghost-mission",
            contributorId: UUID(), outcome: .success, mountType: .chest,
            device: DeviceInfo(model: "m", systemVersion: "18.0"),
            videoDurationSec: 5, videoResolution: Resolution(width: 1920, height: 1080),
            imuSampleCount: 500, imuSampleRateHz: 100,
            hasAudioAnnotation: false, privacyConfirmed: true)
        #expect(viewModel.missionTitle(for: unknown) == "ghost-mission")
    }

    @Test
    func goalProgressReflectsCount() async throws {
        let store = try makeStore()
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov")))
        let viewModel = ContributionViewModel(submissionStore: store)
        await viewModel.load()
        #expect(abs(viewModel.goalProgress - 1.0 / Double(ContributionViewModel.sampleGoal)) < 0.0001)
    }

    @Test
    func missionBreakdownCountsAndSortsByCount() async throws {
        let store = try makeStore()
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"), missionId: "chopsticks-plating"))
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"), missionId: "chopsticks-plating"))
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"), missionId: "egg-handling"))

        let viewModel = ContributionViewModel(submissionStore: store)
        await viewModel.load()
        let breakdown = viewModel.missionBreakdown
        #expect(breakdown.count == 2)
        #expect(breakdown.first?.missionId == "chopsticks-plating")
        #expect(breakdown.first?.count == 2)
        #expect(breakdown.first?.title == MissionCatalog.chopsticksPlating.title)
    }

    @Test
    func deleteRemovesSubmission() async throws {
        let store = try makeStore()
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov")))
        let viewModel = ContributionViewModel(submissionStore: store)
        await viewModel.load()
        let target = try #require(viewModel.submissions.first)

        await viewModel.delete(target)
        #expect(viewModel.submissions.isEmpty)
        #expect(viewModel.summary.total == 0)
    }
}

@MainActor
struct HomeViewModelTests {
    @Test
    func loadPopulatesSummaryAndExposesMissions() async throws {
        let store = SubmissionStore(rootDirectory: try TestSupport.makeTempDirectory())
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov")))

        let viewModel = HomeViewModel(submissionStore: store)
        #expect(!viewModel.missions.isEmpty)
        await viewModel.load()
        #expect(viewModel.summary.total == 1)
    }
}
