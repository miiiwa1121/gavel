import Foundation

/// 供給者（撮影・投稿する協力者）。v1 は端末内の単一プロフィール。
///
/// 識別は招待コード＋表示名の最小構成（本格的な認証基盤は v1 対象外。`requirements.md` §8）。
/// レベニューシェアの受取主体だが、v1 では売買が発生しないため還元は扱わない。
struct Contributor: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    /// 表示名（本人が設定）。
    var displayName: String
    /// 招待コード（限定配布の識別）。
    var inviteCode: String
    /// 推奨マウント位置（オンボーディングで設定）。
    var mountType: MountType
    /// データ利用・再ライセンス同意の受諾日時（未同意なら nil）。
    var consentAcceptedAt: Date?

    init(
        id: UUID = UUID(),
        displayName: String,
        inviteCode: String,
        mountType: MountType = .chest,
        consentAcceptedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.inviteCode = inviteCode
        self.mountType = mountType
        self.consentAcceptedAt = consentAcceptedAt
    }

    /// 同意済みか。撮影・投稿の前提。
    var hasAcceptedConsent: Bool {
        consentAcceptedAt != nil
    }
}
