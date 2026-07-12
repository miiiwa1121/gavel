import SwiftUI

/// 設定／マイページ。v1 は最小（プロフィール・同意状態・アプリ情報の表示）。
struct SettingsView: View {
    @Environment(SessionModel.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section("プロフィール") {
                    if let contributor = session.contributor {
                        LabeledContent("表示名", value: contributor.displayName)
                        LabeledContent("招待コード", value: contributor.inviteCode)
                        LabeledContent("マウント位置", value: contributor.mountType.displayName)
                    } else {
                        Text("未登録")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("同意") {
                    if let acceptedAt = session.contributor?.consentAcceptedAt {
                        Label("同意済み", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(GavelTheme.success)
                        LabeledContent("同意日時") {
                            Text(acceptedAt, format: .dateTime.year().month().day().hour().minute())
                        }
                    } else {
                        Label("未同意", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(GavelTheme.momiji)
                    }
                }

                Section("アプリ情報") {
                    LabeledContent("バージョン", value: AppMetadata.version)
                    LabeledContent("プラットフォーム", value: AppMetadata.platform)
                }

                Section {
                    Text("v1 は限定協力者向けの検証段階です。ウォレット・出金・本人確認（KYC）は公開フェーズで提供します。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
        }
    }
}
