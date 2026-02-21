import simd

extension simd_float4x4 {
    /// Asymmetric frustum projection matrix — the key to the off-axis "window" illusion.
    /// Parameters define the frustum bounds at the near plane.
    static func offAxisPerspective(
        left: Float, right: Float,
        bottom: Float, top: Float,
        near: Float, far: Float
    ) -> simd_float4x4 {
        let rl = right - left
        let tb = top - bottom
        let fn = far - near

        return simd_float4x4(rows: [
            SIMD4<Float>(2 * near / rl, 0, (right + left) / rl, 0),
            SIMD4<Float>(0, 2 * near / tb, (top + bottom) / tb, 0),
            SIMD4<Float>(0, 0, -(far + near) / fn, -2 * far * near / fn),
            SIMD4<Float>(0, 0, -1, 0)
        ])
    }

    /// Standard symmetric perspective projection.
    static func perspective(fovYRadians: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 1 / tanf(fovYRadians * 0.5)
        let x = y / aspect
        let fn = far - near
        return simd_float4x4(rows: [
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, -(far + near) / fn, -2 * far * near / fn),
            SIMD4<Float>(0, 0, -1, 0)
        ])
    }

    /// Look-at view matrix (right-hand, +Y up).
    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let f = normalize(center - eye)
        let s = normalize(cross(f, up))
        let u = cross(s, f)

        return simd_float4x4(rows: [
            SIMD4<Float>(s.x, s.y, s.z, -dot(s, eye)),
            SIMD4<Float>(u.x, u.y, u.z, -dot(u, eye)),
            SIMD4<Float>(-f.x, -f.y, -f.z, dot(f, eye)),
            SIMD4<Float>(0, 0, 0, 1)
        ])
    }

    /// Translation matrix.
    static func translation(_ t: SIMD3<Float>) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(t.x, t.y, t.z, 1)
        return m
    }
}
