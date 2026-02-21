import simd

/// Computes the asymmetric frustum projection that creates the "window into 3D space" illusion.
/// Ported from decorate_3D_portal's offAxisCamera.ts.
struct OffAxisProjection {
    var nearPlane: Float = 0.001
    var farPlane: Float = 10.0

    /// Controls how much the perspective shifts per unit of head movement.
    /// 1.0 = realistic, >1.0 = exaggerated effect, <1.0 = subtle.
    var movementScale: Float = 1.5

    /// Compute the asymmetric frustum projection matrix based on head position.
    func projectionMatrix(
        headPosition: HeadPosition,
        screen: ScreenCalibration
    ) -> simd_float4x4 {
        let halfW = screen.widthMeters / 2
        let halfH = screen.heightMeters / 2
        let dist = max(0.1, headPosition.z)

        let headX = headPosition.x * movementScale
        let headY = headPosition.y * movementScale

        let nearOverDist = nearPlane / dist

        // Frustum bounds shift inversely to head offset
        let left   = (-halfW - headX) * nearOverDist
        let right  = ( halfW - headX) * nearOverDist
        let bottom = (-halfH - headY) * nearOverDist
        let top    = ( halfH - headY) * nearOverDist

        return simd_float4x4.offAxisPerspective(
            left: left, right: right,
            bottom: bottom, top: top,
            near: nearPlane, far: farPlane
        )
    }

    /// Camera position in world space, matching the head offset.
    func cameraPosition(headPosition: HeadPosition) -> SIMD3<Float> {
        SIMD3<Float>(
            headPosition.x * movementScale,
            headPosition.y * movementScale,
            max(0.1, headPosition.z)
        )
    }
}
