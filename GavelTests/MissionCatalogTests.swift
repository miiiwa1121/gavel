import Testing
@testable import Gavel

struct MissionCatalogTests {
    @Test
    func catalogIsNotEmpty() {
        #expect(!MissionCatalog.all.isEmpty)
    }

    @Test
    func missionIDsAreUnique() {
        let ids = MissionCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test
    func lookupByIDReturnsMatch() {
        let target = MissionCatalog.eggHandling
        #expect(MissionCatalog.mission(id: target.id) == target)
    }

    @Test
    func lookupUnknownIDReturnsNil() {
        #expect(MissionCatalog.mission(id: "does-not-exist") == nil)
    }

    @Test
    func allMissionsAreJapanSpecific() {
        // 差別化の柱＝日本特化。v1 の常設ミッションは全て日本特有タスク。
        let allJapanSpecific = MissionCatalog.all.allSatisfy(\.isJapanSpecific)
        #expect(allJapanSpecific)
    }

    @Test
    func durationBoundsAreValid() {
        for mission in MissionCatalog.all {
            #expect(mission.minClipDurationSec > 0)
            #expect(mission.maxClipDurationSec > mission.minClipDurationSec)
        }
    }

    @Test
    func everyMissionHasGuidanceContent() {
        for mission in MissionCatalog.all {
            #expect(!mission.taskDescription.isEmpty)
            #expect(!mission.successConditions.isEmpty)
            #expect(!mission.shootingTips.isEmpty)
        }
    }
}
