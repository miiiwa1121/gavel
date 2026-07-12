import SwiftUI

/// 常設ミッションの一覧（少数固定・マーケットプレイスは持たない）。
struct MissionsView: View {
    private let missions = MissionCatalog.all

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(missions) { mission in
                        NavigationLink(value: mission) {
                            MissionRow(mission: mission)
                        }
                    }
                } footer: {
                    Text("日本特有の手元動作に絞った少数のミッションです。買い手に届ける100件の均質な在庫をつくります。")
                }
            }
            .navigationTitle("ミッション")
            .navigationDestination(for: Mission.self) { mission in
                MissionDetailView(mission: mission)
            }
        }
    }
}
