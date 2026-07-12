import Foundation
import Testing
@testable import Gavel

@MainActor
struct SessionModelTests {
    private func makeStore() throws -> ProfileStore {
        ProfileStore(rootDirectory: try TestSupport.makeTempDirectory())
    }

    @Test
    func bootstrapWithoutProfileGoesToOnboarding() async throws {
        let session = SessionModel(profileStore: try makeStore())
        await session.bootstrap()
        #expect(session.phase == .onboarding)
        #expect(session.contributor == nil)
    }

    @Test
    func bootstrapWithConsentedProfileGoesToMain() async throws {
        let store = try makeStore()
        let contributor = Contributor(
            displayName: "たろう",
            inviteCode: "GAVEL-1",
            consentAcceptedAt: Date(timeIntervalSince1970: 1)
        )
        try await store.save(contributor)

        let session = SessionModel(profileStore: store)
        await session.bootstrap()
        #expect(session.phase == .main)
        #expect(session.contributor == contributor)
    }

    @Test
    func bootstrapWithUnconsentedProfileGoesToOnboarding() async throws {
        let store = try makeStore()
        // consentAcceptedAt が nil のプロフィール（同意前）。
        try await store.save(Contributor(displayName: "a", inviteCode: "b"))

        let session = SessionModel(profileStore: store)
        await session.bootstrap()
        #expect(session.phase == .onboarding)
    }

    @Test
    func completeOnboardingMovesToMain() throws {
        let session = SessionModel(profileStore: try makeStore())
        let contributor = Contributor(displayName: "a", inviteCode: "b", consentAcceptedAt: Date())
        session.completeOnboarding(with: contributor)
        #expect(session.phase == .main)
        #expect(session.contributor == contributor)
    }

    @Test
    func completeOnboardingIgnoresUnconsentedProfile() throws {
        let session = SessionModel(profileStore: try makeStore())
        session.completeOnboarding(with: Contributor(displayName: "a", inviteCode: "b"))  // 未同意
        #expect(session.phase != .main)
        #expect(session.contributor == nil)
    }

    @Test
    func bootstrapRecoversFromCorruptProfile() async throws {
        let root = try TestSupport.makeTempDirectory()
        // 壊れた profile.json を置く（読み込み失敗）。
        try Data("{ not valid".utf8).write(to: root.appendingPathComponent("profile.json"))

        let session = SessionModel(profileStore: ProfileStore(rootDirectory: root))
        await session.bootstrap()
        #expect(session.phase == .onboarding)
        #expect(session.contributor == nil)
    }
}
