import SwiftUI

/// フェーズに応じてオンボーディングと本編を切り替えるルート。
struct RootView: View {
    @Environment(SessionModel.self) private var session

    var body: some View {
        switch session.phase {
        case .loading:
            ProgressView()
                .controlSize(.large)
        case .onboarding:
            OnboardingView()
        case .main:
            MainTabView()
        }
    }
}
