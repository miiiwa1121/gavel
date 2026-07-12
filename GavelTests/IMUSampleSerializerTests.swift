import Foundation
import Testing
@testable import Gavel

struct IMUSampleSerializerTests {
    @Test
    func roundTripPreservesSamples() throws {
        let samples = TestSupport.makeIMUSamples(count: 50, rateHz: 100)
        let data = try IMUSampleSerializer.encode(samples)
        let decoded = try IMUSampleSerializer.decode(data)
        #expect(decoded == samples)
    }

    @Test
    func encodesOneLinePerSample() throws {
        let samples = TestSupport.makeIMUSamples(count: 5, rateHz: 100)
        let data = try IMUSampleSerializer.encode(samples)
        let lineCount = data.split(separator: 0x0A, omittingEmptySubsequences: true).count
        #expect(lineCount == 5)
    }

    @Test
    func emptyInputProducesEmptyData() throws {
        let data = try IMUSampleSerializer.encode([])
        #expect(data.isEmpty)
        #expect(try IMUSampleSerializer.decode(data).isEmpty)
    }

    @Test
    func decodeSkipsBlankLines() throws {
        let samples = TestSupport.makeIMUSamples(count: 2, rateHz: 50)
        var data = try IMUSampleSerializer.encode(samples)
        data.append(Data([0x0A, 0x0A]))  // 余分な空行
        let decoded = try IMUSampleSerializer.decode(data)
        #expect(decoded == samples)
    }
}
