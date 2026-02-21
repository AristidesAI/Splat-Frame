import Observation
import ReplayKit
import SwiftUI

@Observable
final class AppState {
    enum Tab: Hashable {
        case cube, settings
    }

    var selectedTab: Tab = .cube
    var showCalibrationOverlay = false
    var isRecording = false

    /// Holds the recording preview controller to present as a sheet
    var recordingPreviewVC: RPPreviewViewController?

    /// Toggles portrait-rectangle room shape
    var isRectangleMode = false

    /// Toggles face overlay visibility
    var showSilhouette = false

    /// Toggles gyroscope/accelerometer phone-motion tracking
    var gyroEnabled = true

    /// Zoom factor for the room geometry
    var zoomScale: CGFloat = 0.6

    // MARK: - Effects
    var wobbleEnabled = false
    var inertiaEnabled = false
    var bounceEnabled = false

    // MARK: - Line Effects
    var lineWobbleEnabled = false
    var lineInertiaEnabled = false
    var lineBounceEnabled = false

    let headTracker = HeadTrackingService()
    let deviceMotion = DeviceMotionService()
    let motionEffects = MotionEffectsService()
    let cubeController = CubeSceneController()

    /// Face content assignments for the cube
    var faceContent: [CubeFace: FaceContentType] = [:]

    init() {
        cubeController.headTracker = headTracker
        cubeController.deviceMotion = deviceMotion
        cubeController.motionEffects = motionEffects
        cubeController.setRoomShape(isRectangleMode ? .portrait : .cube)
        cubeController.setZoomScale(Float(zoomScale))
    }
}
