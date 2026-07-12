import Testing
@testable import Gavel

/// M0 のパイプライン疎通用テスト。ビルド／テスト／静的解析が緑になることを確認する。
struct AppMetadataTests {
    @Test
    func displayNameIsCodename() {
        #expect(AppMetadata.displayName == "gavel")
    }

    @Test
    func versionMatchesProjectDefinition() {
        #expect(AppMetadata.version == "0.1.0")
    }

    @Test
    func platformIsIOS() {
        #expect(AppMetadata.platform == "iOS")
    }
}
