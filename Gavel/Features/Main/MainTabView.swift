import SwiftUI

/// 本編のタブ。撮影は独立タブではなくミッション詳細から開始する（1タスク=1実演の導線）。
struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("ホーム", systemImage: "house") {
                HomeView()
            }
            Tab("ミッション", systemImage: "list.bullet.rectangle") {
                MissionsView()
            }
            Tab("記録", systemImage: "chart.bar") {
                ContributionView()
            }
            Tab("設定", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
