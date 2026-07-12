import Foundation

/// オンボーディング（同意 → プロフィール登録 → 撮影ガイド）の状態と操作。
///
/// 品質が命であり協力者は撮影に不慣れなため、最初に撮り方を教える設計を重視する
/// （`requirements.md` §8）。同意なしには先へ進めない。
@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome
        case consent
        case profile
        case tutorial
    }

    private let profileStore: ProfileStore
    private let onComplete: (Contributor) -> Void

    var step: Step = .welcome
    var displayName = ""
    var inviteCode = ""
    var mountType: MountType = .chest
    var consentAccepted = false
    var isSaving = false
    var errorMessage: String?
    /// 完了済みか。同意記録の二重付与・二重保存を防ぐ。
    private var didComplete = false

    init(profileStore: ProfileStore, onComplete: @escaping (Contributor) -> Void) {
        self.profileStore = profileStore
        self.onComplete = onComplete
    }

    /// プロフィール入力が有効か（表示名・招待コードが空でない）。
    var isProfileValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 現在のステップから次へ進めるか。
    var canAdvance: Bool {
        switch step {
        case .welcome, .tutorial: true
        case .consent: consentAccepted
        case .profile: isProfileValid
        }
    }

    /// 次へ進む。最後のステップでは保存して完了する。
    func advance() async {
        guard canAdvance, !isSaving else { return }
        if step == .tutorial {
            await finish()
            return
        }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    /// 前へ戻る。
    func back() {
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    private func finish() async {
        // 同意記録は「実際に同意した」ことから導出する。順序頼みにせず明示ガードで守る。
        guard consentAccepted, !isSaving, !didComplete else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let contributor = Contributor(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            inviteCode: inviteCode.trimmingCharacters(in: .whitespacesAndNewlines),
            mountType: mountType,
            consentAcceptedAt: Date()
        )
        do {
            try await profileStore.save(contributor)
            didComplete = true
            onComplete(contributor)
        } catch {
            errorMessage = "プロフィールの保存に失敗しました。時間をおいて再度お試しください。"
        }
    }
}
