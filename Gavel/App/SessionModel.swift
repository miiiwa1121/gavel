import Foundation

/// アプリの起動フェーズと現在の供給者プロフィールを保持する。
///
/// 起動時に保存済みプロフィールを読み、同意済みなら本編、未同意/未登録ならオンボーディングへ。
@MainActor
@Observable
final class SessionModel {
    enum Phase: Equatable {
        case loading
        case onboarding
        case main
    }

    private let profileStore: ProfileStore
    private(set) var phase: Phase = .loading
    private(set) var contributor: Contributor?

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore
    }

    /// 起動時に一度呼ぶ。保存済みプロフィールを読み込みフェーズを決める。
    func bootstrap() async {
        do {
            apply(try await profileStore.load())
        } catch {
            // 壊れたプロフィールは作り直せるので、読めなければオンボーディングへ。
            contributor = nil
            phase = .onboarding
        }
    }

    /// オンボーディング完了（同意済みプロフィール確定）で本編へ遷移。
    /// 未同意のプロフィールでは本編へ入れない（`apply` と対称の同意チェック）。
    func completeOnboarding(with contributor: Contributor) {
        guard contributor.hasAcceptedConsent else { return }
        self.contributor = contributor
        phase = .main
    }

    private func apply(_ loaded: Contributor?) {
        contributor = loaded
        phase = (loaded?.hasAcceptedConsent == true) ? .main : .onboarding
    }
}
