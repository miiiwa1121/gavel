import Foundation
import Testing
@testable import Gavel

struct SubmissionStoreTests {
    @Test
    func saveWritesFolderWithOriginals() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let video = try TestSupport.makeTempFile(extension: "mov", contents: "video-bytes")
        let draft = TestSupport.makeDraft(videoURL: video)

        let submission = try await store.save(draft)

        let folder = await store.folderURL(for: submission.id)
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: folder.appendingPathComponent("manifest.json").path))
        #expect(fileManager.fileExists(atPath: folder.appendingPathComponent("video.mov").path))
        #expect(fileManager.fileExists(atPath: folder.appendingPathComponent("imu.jsonl").path))
        // 映像原本が投稿フォルダへ移動している（一時ファイルは消える）。
        #expect(!fileManager.fileExists(atPath: video.path))
        #expect(submission.imuSampleCount == draft.imuSamples.count)
        #expect(submission.syncState == .pendingSync)
    }

    @Test
    func savedIMUIsReadableBack() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let video = try TestSupport.makeTempFile(extension: "mov")
        let draft = TestSupport.makeDraft(videoURL: video, durationSec: 4, rateHz: 100)

        let submission = try await store.save(draft)
        let folder = await store.folderURL(for: submission.id)
        let imuData = try Data(contentsOf: folder.appendingPathComponent("imu.jsonl"))
        let decoded = try IMUSampleSerializer.decode(imuData)
        #expect(decoded.count == draft.imuSamples.count)
        #expect(decoded == draft.imuSamples)
    }

    @Test
    func saveWithAudioAnnotationStoresFile() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let video = try TestSupport.makeTempFile(extension: "mov")
        let audio = try TestSupport.makeTempFile(extension: "m4a")
        let draft = TestSupport.makeDraft(videoURL: video, audioURL: audio)

        let submission = try await store.save(draft)
        #expect(submission.hasAudioAnnotation)
        let folder = await store.folderURL(for: submission.id)
        #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("annotation.m4a").path))
    }

    @Test
    func allReturnsSavedSubmissionsNewestFirst() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)

        let older = TestSupport.makeDraft(videoURL: try TestSupport.makeTempFile(extension: "mov"))
        var olderDated = older
        olderDated.createdAt = Date(timeIntervalSince1970: 1_000)
        _ = try await store.save(olderDated)

        var newerDated = TestSupport.makeDraft(videoURL: try TestSupport.makeTempFile(extension: "mov"))
        newerDated.createdAt = Date(timeIntervalSince1970: 2_000)
        _ = try await store.save(newerDated)

        let all = try await store.all()
        #expect(all.count == 2)
        #expect(all.first?.createdAt == newerDated.createdAt)  // 新しい順
    }

    @Test
    func summaryCountsOutcomesAndMissions() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)

        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"),
            missionId: "chopsticks-plating", outcome: .success))
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"),
            missionId: "chopsticks-plating", outcome: .failure))
        _ = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"),
            missionId: "egg-handling", outcome: .success))

        let summary = try await store.summary()
        #expect(summary.total == 3)
        #expect(summary.successCount == 2)
        #expect(summary.failureCount == 1)
        #expect(summary.countByMission["chopsticks-plating"] == 2)
        #expect(summary.countByMission["egg-handling"] == 1)
    }

    @Test
    func deleteRemovesSubmission() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let submission = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov")))

        try await store.delete(id: submission.id)
        let all = try await store.all()
        #expect(all.isEmpty)
    }

    @Test
    func saveThrowsWhenVideoMissing() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let missingVideo = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID().uuidString).mov")
        let draft = TestSupport.makeDraft(videoURL: missingVideo)

        await #expect(throws: SubmissionStoreError.videoFileMissing) {
            _ = try await store.save(draft)
        }
    }

    @Test
    func allReturnsEmptyForFreshStore() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        #expect(try await store.all().isEmpty)
    }

    @Test
    func saveThrowsWhenIMUEmpty() async throws {
        // 映像単体・IMU単体の投稿は作らない不変ルール（中核設計A）を関所で強制。
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let video = try TestSupport.makeTempFile(extension: "mov")
        var draft = TestSupport.makeDraft(videoURL: video)
        draft.imuSamples = []

        await #expect(throws: SubmissionStoreError.imuSamplesMissing) {
            _ = try await store.save(draft)
        }
        // 失敗時に元の一時ファイルは残る（黙って失わない）。投稿も作られない。
        #expect(FileManager.default.fileExists(atPath: video.path))
        #expect(try await store.all().isEmpty)
    }

    @Test
    func saveThrowsWhenAudioMissing() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let video = try TestSupport.makeTempFile(extension: "mov")
        let missingAudio = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).m4a")
        let draft = TestSupport.makeDraft(videoURL: video, audioURL: missingAudio)

        await #expect(throws: SubmissionStoreError.audioFileMissing) {
            _ = try await store.save(draft)
        }
        #expect(FileManager.default.fileExists(atPath: video.path))
    }

    @Test
    func allSkipsFolderWithoutManifest() async throws {
        // manifest 不在の未完成フォルダはコミットマーカー設計で無視される。
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let valid = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov")))

        let strayFolder = await store.folderURL(for: UUID())
        try FileManager.default.createDirectory(at: strayFolder, withIntermediateDirectories: true)

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.id == valid.id)
    }

    @Test
    func allSkipsCorruptManifest() async throws {
        // 1件の壊れた manifest で全履歴が読めなくならない。
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let valid = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov")))

        let corruptFolder = await store.folderURL(for: UUID())
        try FileManager.default.createDirectory(at: corruptFolder, withIntermediateDirectories: true)
        try Data("this is not valid json".utf8)
            .write(to: corruptFolder.appendingPathComponent("manifest.json"))

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.id == valid.id)
    }

    @Test
    func mediaResolvesFileURLs() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = SubmissionStore(rootDirectory: root)
        let submission = try await store.save(TestSupport.makeDraft(
            videoURL: try TestSupport.makeTempFile(extension: "mov"),
            audioURL: try TestSupport.makeTempFile(extension: "m4a")))

        let media = try #require(try await store.media(for: submission.id))
        #expect(media.video.lastPathComponent == "video.mov")
        #expect(media.imu.lastPathComponent == "imu.jsonl")
        #expect(media.audioAnnotation?.lastPathComponent == "annotation.m4a")
        #expect(FileManager.default.fileExists(atPath: media.video.path))
    }

    @Test
    func mediaReturnsNilForUnknownID() async throws {
        let store = SubmissionStore(rootDirectory: try TestSupport.makeTempDirectory())
        #expect(try await store.media(for: UUID()) == nil)
    }
}
