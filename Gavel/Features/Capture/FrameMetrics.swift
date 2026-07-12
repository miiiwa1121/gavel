import CoreGraphics
import Foundation

/// 映像フレーム（CGImage）から品質指標を計算する純粋ロジック。
///
/// モックの発想（ダウンスケール→グレースケール→平均輝度＋ラプラシアン分散）を踏襲。CGImage を
/// 入力に取るため、カメラ実機なしでも合成画像で単体テストできる。
enum FrameMetrics {
    /// - Returns: brightness（平均輝度 0..1）と sharpness（ラプラシアン分散の標準偏差）。
    static func evaluate(_ image: CGImage, targetWidth: Int = 140) -> (brightness: Double, sharpness: Double) {
        let width = max(2, targetWidth)
        let scale = Double(width) / Double(max(image.width, 1))
        let height = max(2, Int((Double(image.height) * scale).rounded()))
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        // CGContext 自身にバッファを確保させる（data: nil）。context.data の寿命は context に一致し、
        // 描画→読み出しを安全に行える。
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return (0, 0)
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let base = context.data else { return (0, 0) }
        let pixels = base.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)

        // グレースケール化と平均輝度。
        let pixelCount = width * height
        var gray = [Double](repeating: 0, count: pixelCount)
        var lumaSum = 0.0
        for index in 0..<pixelCount {
            let red = Double(pixels[index * 4])
            let green = Double(pixels[index * 4 + 1])
            let blue = Double(pixels[index * 4 + 2])
            let luma = 0.299 * red + 0.587 * green + 0.114 * blue
            gray[index] = luma
            lumaSum += luma
        }
        let brightness = (lumaSum / Double(pixelCount)) / 255.0

        // ラプラシアン分散（鮮鋭度）。
        var sum = 0.0
        var sumSquares = 0.0
        var count = 0.0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = y * width + x
                let laplacian = gray[idx - 1] + gray[idx + 1] + gray[idx - width] + gray[idx + width] - 4 * gray[idx]
                sum += laplacian
                sumSquares += laplacian * laplacian
                count += 1
            }
        }
        guard count > 0 else { return (brightness, 0) }
        let mean = sum / count
        let variance = sumSquares / count - mean * mean
        let sharpness = max(0, variance).squareRoot()
        return (brightness, sharpness)
    }
}
