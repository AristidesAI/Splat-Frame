import SwiftUI
import MetalKit

/// UIViewRepresentable wrapping MTKView for gaussian splat rendering.
struct SplatRenderView: UIViewRepresentable {
    let controller: SplatRenderController

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = controller.device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.preferredFramesPerSecond = 60
        mtkView.delegate = controller
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
