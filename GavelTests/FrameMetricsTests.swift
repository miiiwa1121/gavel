import CoreGraphics
import Testing
@testable import Gavel

struct FrameMetricsTests {
    /// 各ピクセルのグレー値を `fill(x, y)` で決める合成 CGImage を作る。
    private func makeImage(size: Int = 64, fill: (Int, Int) -> UInt8) throws -> CGImage {
        let bytesPerRow = size * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = try #require(CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo))
        let base = try #require(context.data)
        let pixels = base.bindMemory(to: UInt8.self, capacity: bytesPerRow * size)
        for y in 0..<size {
            for x in 0..<size {
                let value = fill(x, y)
                let idx = (y * size + x) * 4
                pixels[idx] = value
                pixels[idx + 1] = value
                pixels[idx + 2] = value
                pixels[idx + 3] = 255
            }
        }
        return try #require(context.makeImage())
    }

    @Test
    func brighterImageHasHigherBrightness() throws {
        let dark = try makeImage { _, _ in 20 }
        let bright = try makeImage { _, _ in 220 }
        let darkMetrics = FrameMetrics.evaluate(dark)
        let brightMetrics = FrameMetrics.evaluate(bright)
        #expect(brightMetrics.brightness > darkMetrics.brightness)
        #expect(darkMetrics.brightness < 0.2)
        #expect(brightMetrics.brightness > 0.7)
    }

    @Test
    func checkerboardIsSharperThanSolid() throws {
        let solid = try makeImage { _, _ in 128 }
        let checker = try makeImage { x, y in (x + y).isMultiple(of: 2) ? 0 : 255 }
        let solidMetrics = FrameMetrics.evaluate(solid)
        let checkerMetrics = FrameMetrics.evaluate(checker)
        #expect(checkerMetrics.sharpness > solidMetrics.sharpness)
        #expect(solidMetrics.sharpness < 1.0)  // 一様面はほぼ鮮鋭度ゼロ
    }
}
