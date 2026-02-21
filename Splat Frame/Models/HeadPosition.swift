import Foundation
import simd

struct HeadPosition: Sendable {
    /// Horizontal offset in meters (positive = right)
    var x: Float
    /// Vertical offset in meters (positive = up)
    var y: Float
    /// Distance from screen in meters (always positive)
    var z: Float
    var timestamp: TimeInterval

    static let zero = HeadPosition(x: 0, y: 0, z: 0.4, timestamp: 0)

    var simd3: SIMD3<Float> {
        SIMD3<Float>(x, y, z)
    }
}
