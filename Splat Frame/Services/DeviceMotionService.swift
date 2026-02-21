import CoreMotion
import Observation

/// Tracks device movement via accelerometer + gyroscope to complement ARKit head tracking.
/// Provides a smoothed device tilt offset that adds parallax from phone movement.
@Observable
final class DeviceMotionService {
    private let motionManager = CMMotionManager()
    private var smootherPitch = ExponentialSmoother(alpha: 0.3)
    private var smootherRoll = ExponentialSmoother(alpha: 0.3)

    /// Smoothed device tilt offset in meters (pitch = Y, roll = X)
    private(set) var tiltOffset: SIMD2<Float> = .zero

    /// Raw rotation rate (rad/s) — used by MotionEffectsService for wobble/inertia
    private(set) var rotationRate: SIMD3<Float> = .zero

    /// Whether gyro tracking is currently running
    private(set) var isActive = false

    /// Whether the device has gyroscope hardware
    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    /// Sensitivity: how much device tilt translates to parallax offset
    var sensitivity: Float = 0.03

    /// Reference attitude captured at start or reset — tilt is relative to this
    private var referenceAttitude: CMAttitude?

    func start() {
        guard isAvailable, !isActive else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            if self.referenceAttitude == nil {
                self.referenceAttitude = motion.attitude.copy() as? CMAttitude
            }
            guard let ref = self.referenceAttitude else { return }

            // Compute tilt relative to reference
            let attitude = motion.attitude
            attitude.multiply(byInverseOf: ref)

            let pitch = Float(attitude.pitch) // forward/back tilt
            let roll = Float(attitude.roll)   // left/right tilt

            let smoothedPitch = self.smootherPitch.smooth(pitch)
            let smoothedRoll = self.smootherRoll.smooth(roll)

            self.tiltOffset = SIMD2<Float>(
                smoothedRoll * self.sensitivity,
                -smoothedPitch * self.sensitivity
            )

            // Expose raw rotation rate for effects
            let rr = motion.rotationRate
            self.rotationRate = SIMD3<Float>(Float(rr.x), Float(rr.y), Float(rr.z))
        }
        isActive = true
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        tiltOffset = .zero
        referenceAttitude = nil
        smootherPitch.reset()
        smootherRoll.reset()
    }

    func resetReference() {
        referenceAttitude = nil
        smootherPitch.reset()
        smootherRoll.reset()
        tiltOffset = .zero
    }
}
