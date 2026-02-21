import simd
import Observation

/// Computes dynamic motion effects (wobble, inertia, bounce) from gyroscope data.
/// Applied per-frame in the SceneKit render loop to the room container.
@Observable
final class MotionEffectsService {

    // MARK: - Wobble (jello deformation)

    /// Current wobble angular offset for each axis (radians)
    private(set) var wobbleOffset: SIMD3<Float> = .zero

    /// Wobble spring state
    private var wobbleVelocity: SIMD3<Float> = .zero

    /// Spring stiffness — higher = snappier return
    var wobbleStiffness: Float = 120.0
    /// Spring damping — higher = less oscillation
    var wobbleDamping: Float = 6.0
    /// How much gyro angular velocity feeds into wobble
    var wobbleSensitivity: Float = 0.08

    // MARK: - Inertia (sliding momentum)

    /// Current inertia position offset (meters)
    private(set) var inertiaOffset: SIMD2<Float> = .zero

    /// Inertia velocity
    private var inertiaVelocity: SIMD2<Float> = .zero

    /// Friction coefficient — higher = stops faster
    var inertiaFriction: Float = 3.0
    /// How much gyro feeds into inertia push
    var inertiaSensitivity: Float = 0.012

    // MARK: - Bounce (rubber band at edges)

    /// Current bounce offset (meters)
    private(set) var bounceOffset: SIMD2<Float> = .zero

    private var bounceVelocity: SIMD2<Float> = .zero
    /// Edge limit — how far the room drifts before bouncing back
    var bounceLimit: Float = 0.03
    var bounceStiffness: Float = 200.0
    var bounceDamping: Float = 8.0

    // MARK: - Update

    /// Call every frame with the current gyroscope rotation rate and timestep.
    /// - Parameters:
    ///   - rotationRate: angular velocity from DeviceMotion (pitch, roll, yaw) in rad/s
    ///   - dt: time since last frame
    ///   - wobbleEnabled: whether wobble effect is active
    ///   - inertiaEnabled: whether inertia effect is active
    ///   - bounceEnabled: whether bounce effect is active
    func update(
        rotationRate: SIMD3<Float>,
        dt: Float,
        wobbleEnabled: Bool,
        inertiaEnabled: Bool,
        bounceEnabled: Bool
    ) {
        let clampedDt = min(dt, 1.0 / 30.0) // cap to prevent explosion

        // --- Wobble (spring-mass system) ---
        if wobbleEnabled {
            // External force from phone rotation
            let wobbleForce = rotationRate * wobbleSensitivity

            // Spring: F = -kx - cv + external
            let springForce = -wobbleStiffness * wobbleOffset - wobbleDamping * wobbleVelocity
            let totalForce = springForce + SIMD3<Float>(wobbleForce.y, wobbleForce.x, wobbleForce.z) * 50

            wobbleVelocity += totalForce * clampedDt
            wobbleOffset += wobbleVelocity * clampedDt

            // Clamp to prevent extreme wobble
            wobbleOffset = simd_clamp(wobbleOffset, SIMD3<Float>(repeating: -0.15), SIMD3<Float>(repeating: 0.15))
        } else {
            wobbleOffset = .zero
            wobbleVelocity = .zero
        }

        // --- Inertia (momentum-based sliding) ---
        if inertiaEnabled {
            // Push from rotation
            let push = SIMD2<Float>(rotationRate.y, -rotationRate.x) * inertiaSensitivity

            inertiaVelocity += push
            // Apply friction (exponential decay)
            inertiaVelocity *= exp(-inertiaFriction * clampedDt)
            inertiaOffset += inertiaVelocity * clampedDt

            // Soft clamp
            let maxDrift: Float = 0.05
            inertiaOffset = simd_clamp(inertiaOffset, SIMD2<Float>(repeating: -maxDrift), SIMD2<Float>(repeating: maxDrift))
        } else {
            inertiaOffset = .zero
            inertiaVelocity = .zero
        }

        // --- Bounce (rubber-band at edges) ---
        if bounceEnabled {
            // Push from rotation
            let push = SIMD2<Float>(rotationRate.y, -rotationRate.x) * 0.008
            bounceVelocity += push

            // Spring force pulling back when beyond limits
            var restoreForce = SIMD2<Float>.zero
            for axis in 0...1 {
                if bounceOffset[axis] > bounceLimit {
                    restoreForce[axis] = -bounceStiffness * (bounceOffset[axis] - bounceLimit)
                } else if bounceOffset[axis] < -bounceLimit {
                    restoreForce[axis] = -bounceStiffness * (bounceOffset[axis] + bounceLimit)
                }
            }

            bounceVelocity += restoreForce * clampedDt
            bounceVelocity *= exp(-bounceDamping * clampedDt)
            bounceOffset += bounceVelocity * clampedDt

            // Hard clamp safety
            let maxBounce: Float = 0.08
            bounceOffset = simd_clamp(bounceOffset, SIMD2<Float>(repeating: -maxBounce), SIMD2<Float>(repeating: maxBounce))
        } else {
            bounceOffset = .zero
            bounceVelocity = .zero
        }
    }

    /// Reset all effect states to zero
    func reset() {
        wobbleOffset = .zero
        wobbleVelocity = .zero
        inertiaOffset = .zero
        inertiaVelocity = .zero
        bounceOffset = .zero
        bounceVelocity = .zero
    }
}
