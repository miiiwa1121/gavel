import SwiftUI
import AVFoundation

/// AVCaptureSession のライブプレビュー。実機のみ描画（シミュレータは黒画面）。
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {}

    /// レイヤが常に `AVCaptureVideoPreviewLayer` になる UIView。
    final class PreviewContainerView: UIView {
        // UIKit の layerClass は override class var が必須（static にはできない）。
        // swiftlint:disable:next static_over_final_class
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                return AVCaptureVideoPreviewLayer()
            }
            return layer
        }
    }
}
