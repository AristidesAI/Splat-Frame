import SwiftUI
import SceneKit

/// UIViewRepresentable wrapping SCNView for the parallax cube rendering.
struct CubeSceneView: UIViewRepresentable {
    let controller: CubeSceneController

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = controller.scene
        scnView.pointOfView = controller.cameraNode
        scnView.delegate = controller
        scnView.backgroundColor = .clear
        scnView.isPlaying = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.pointOfView = controller.cameraNode
    }
}
