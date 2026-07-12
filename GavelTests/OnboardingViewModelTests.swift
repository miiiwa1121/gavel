import Foundation
import Testing
@testable import Gavel

@MainActor
struct OnboardingViewModelTests {
    private func makeStore() throws -> ProfileStore {
        ProfileStore(rootDirectory: try TestSupport.makeTempDirectory())
    }

    @Test
    func consentIsRequiredToLeaveConsentStep() async throws {
        let viewModel = OnboardingViewModel(profileStore: try makeStore(), onComplete: { _ in })
        await viewModel.advance()  // welcome -> consent
        #expect(viewModel.step == .consent)
        #expect(viewModel.canAdvance == false)

        await viewModel.advance()  // 同意なしでは進めない
        #expect(viewModel.step == .consent)

        viewModel.consentAccepted = true
        #expect(viewModel.canAdvance)
        await viewModel.advance()
        #expect(viewModel.step == .profile)
    }

    @Test
    func profileValidationRequiresNameAndCode() throws {
        let viewModel = OnboardingViewModel(profileStore: try makeStore(), onComplete: { _ in })
        viewModel.step = .profile
        #expect(!viewModel.isProfileValid)
        viewModel.displayName = "たろう"
        #expect(!viewModel.isProfileValid)
        viewModel.inviteCode = "GAVEL-1"
        #expect(viewModel.isProfileValid)
        #expect(viewModel.canAdvance)
    }

    @Test
    func finishSavesConsentedContributorAndTrimsInput() async throws {
        let store = try makeStore()
        var completed: Contributor?
        let viewModel = OnboardingViewModel(profileStore: store, onComplete: { completed = $0 })
        viewModel.consentAccepted = true
        viewModel.displayName = "  たろう  "
        viewModel.inviteCode = "  GAVEL-1  "
        viewModel.mountType = .head
        viewModel.step = .tutorial

        await viewModel.advance()  // tutorial -> finish

        #expect(completed?.displayName == "たろう")
        #expect(completed?.inviteCode == "GAVEL-1")
        #expect(completed?.mountType == .head)
        #expect(completed?.hasAcceptedConsent == true)

        // ディスク往復で consentAcceptedAt は秒粒度になるため、Date 完全一致でなく安定フィールドで検証。
        let saved = try await store.load()
        #expect(saved?.id == completed?.id)
        #expect(saved?.displayName == "たろう")
        #expect(saved?.inviteCode == "GAVEL-1")
        #expect(saved?.mountType == .head)
        #expect(saved?.hasAcceptedConsent == true)
    }

    @Test
    func finishSetsErrorWhenSaveFails() async throws {
        // 既存ファイルを root に見立てると createDirectory が失敗し save が throw する。
        let fileAsRoot = try TestSupport.makeTempFile(extension: "dat")
        let store = ProfileStore(rootDirectory: fileAsRoot)
        var completedCount = 0
        let viewModel = OnboardingViewModel(profileStore: store, onComplete: { _ in completedCount += 1 })
        viewModel.consentAccepted = true
        viewModel.displayName = "a"
        viewModel.inviteCode = "b"
        viewModel.step = .tutorial

        await viewModel.advance()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSaving == false)   // defer で戻る
        #expect(viewModel.step == .tutorial)   // 再試行できるよう留まる
        #expect(completedCount == 0)
    }

    @Test
    func finishRunsOnlyOnce() async throws {
        let store = try makeStore()
        var completedCount = 0
        let viewModel = OnboardingViewModel(profileStore: store, onComplete: { _ in completedCount += 1 })
        viewModel.consentAccepted = true
        viewModel.displayName = "a"
        viewModel.inviteCode = "b"
        viewModel.step = .tutorial

        await viewModel.advance()
        await viewModel.advance()  // didComplete により no-op

        #expect(completedCount == 1)
    }

    @Test
    func finishRequiresConsentEvenIfReachedDirectly() async throws {
        // ステップを直接 tutorial にしても、同意していなければ完了しない（明示ガード）。
        let store = try makeStore()
        var completedCount = 0
        let viewModel = OnboardingViewModel(profileStore: store, onComplete: { _ in completedCount += 1 })
        viewModel.consentAccepted = false
        viewModel.displayName = "a"
        viewModel.inviteCode = "b"
        viewModel.step = .tutorial

        await viewModel.advance()

        #expect(completedCount == 0)
        #expect(try await store.load() == nil)
    }

    @Test
    func backReturnsToPreviousStepAndClampsAtStart() async throws {
        let viewModel = OnboardingViewModel(profileStore: try makeStore(), onComplete: { _ in })
        await viewModel.advance()  // welcome -> consent
        #expect(viewModel.step == .consent)
        viewModel.back()
        #expect(viewModel.step == .welcome)
        viewModel.back()  // 先頭より前へは行かない
        #expect(viewModel.step == .welcome)
    }
}
