import SwiftUI

/// アプリのエントリポイント。
///
/// gavel の C 側アプリ（供給側＝データ収集アプリ）。v1 は限定協力者が
/// 一人称マウント撮影で「映像＋IMU」を収集し、ローカルに保持する最小構成。
/// 詳細は `docs/tech/customer/requirements.md` を参照。
@main
struct GavelApp: App {
    @State private var container: AppContainer
    @State private var session: SessionModel

    init() {
        let container = AppContainer.live()
        _container = State(initialValue: container)
        _session = State(initialValue: SessionModel(profileStore: container.profileStore))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(session)
                .tint(GavelTheme.indigo)
                .task { await session.bootstrap() }
        }
    }
}
