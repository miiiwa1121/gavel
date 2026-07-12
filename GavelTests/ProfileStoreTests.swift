import Foundation
import Testing
@testable import Gavel

struct ProfileStoreTests {
    @Test
    func loadReturnsNilWhenNoProfile() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = ProfileStore(rootDirectory: root)
        #expect(try await store.load() == nil)
    }

    @Test
    func saveThenLoadRoundTrips() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = ProfileStore(rootDirectory: root)
        let contributor = Contributor(
            displayName: "テスト太郎",
            inviteCode: "INVITE-123",
            mountType: .head,
            consentAcceptedAt: Date(timeIntervalSince1970: 5_000)
        )
        try await store.save(contributor)
        let loaded = try await store.load()
        #expect(loaded == contributor)
        #expect(loaded?.hasAcceptedConsent == true)
    }

    @Test
    func clearRemovesProfile() async throws {
        let root = try TestSupport.makeTempDirectory()
        let store = ProfileStore(rootDirectory: root)
        try await store.save(Contributor(displayName: "A", inviteCode: "B"))
        try await store.clear()
        #expect(try await store.load() == nil)
    }
}
