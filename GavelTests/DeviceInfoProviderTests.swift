import Testing
@testable import Gavel

struct DeviceInfoProviderTests {
    @Test
    func hardwareModelIsNonEmpty() {
        // シミュレータでは SIMULATOR_MODEL_IDENTIFIER、実機では utsname から得る。
        #expect(!DeviceInfoProvider.hardwareModel().isEmpty)
    }
}
