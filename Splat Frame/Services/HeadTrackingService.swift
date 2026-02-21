import ARKit
import Observation

@Observable
final class HeadTrackingService: NSObject {
    private let session = ARSession()
    private var smootherX = ExponentialSmoother(alpha: 0.25)
    private var smootherY = ExponentialSmoother(alpha: 0.25)
    private var smootherZ = ExponentialSmoother(alpha: 0.25)

    private(set) var currentPosition: HeadPosition = .zero
    private(set) var isTracking = false
    private(set) var isSupported = ARFaceTrackingConfiguration.isSupported

    /// Boundary contour chains of the face mesh (head outline + features).
    /// Updated every frame from ARKit face mesh geometry.
    private(set) var faceContours: [[CGPoint]] = []

    /// Calibration offset: the raw position captured when user taps "reset"
    private var originOffset: SIMD3<Float> = .zero

    /// Smoothing factor (adjustable from Settings)
    var smoothingAlpha: Float = 0.25 {
        didSet {
            smootherX.alpha = smoothingAlpha
            smootherY.alpha = smoothingAlpha
            smootherZ.alpha = smoothingAlpha
        }
    }

    func start() {
        guard isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false
        session.delegate = self
        session.run(config)
        isTracking = true
    }

    func pause() {
        session.pause()
        isTracking = false
    }

    /// Capture current raw position as the new origin — call when user taps "recenter"
    func resetOrigin() {
        originOffset = currentPosition.simd3
        smootherX.reset()
        smootherY.reset()
        smootherZ.reset()
    }
}

extension HeadTrackingService: @preconcurrency ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else { return }

        // Face transform: column 3 holds translation (x, y, z, w)
        let t = faceAnchor.transform.columns.3

        // Extract face outline boundary chains
        let outlines = Self.extractFaceOutline(from: faceAnchor.geometry)

        Task { @MainActor in
            let rawX = t.x
            let rawY = t.y
            let rawZ = abs(t.z) // distance is always positive

            self.currentPosition = HeadPosition(
                x: self.smootherX.smooth(rawX - self.originOffset.x),
                y: self.smootherY.smooth(rawY - self.originOffset.y),
                z: self.smootherZ.smooth(max(0.1, rawZ)),
                timestamp: Date.timeIntervalSinceReferenceDate
            )
            self.faceContours = outlines
        }
    }

    /// Extract all face boundary chains by finding mesh edge vertices.
    /// Boundary edges belong to only one triangle. Multiple chains capture
    /// the head outline plus inner features (mouth, eyes).
    nonisolated private static func extractFaceOutline(
        from geometry: ARFaceGeometry
    ) -> [[CGPoint]] {
        let verts = geometry.vertices
        let vertexCount = verts.count
        guard vertexCount > 0 else { return [] }

        let triangleCount = geometry.triangleCount
        let indices = geometry.triangleIndices

        struct Edge: Hashable {
            let a: Int16, b: Int16
            init(_ v0: Int16, _ v1: Int16) {
                a = min(v0, v1)
                b = max(v0, v1)
            }
        }

        var edgeCount: [Edge: Int] = [:]
        edgeCount.reserveCapacity(triangleCount * 3)

        for t in 0..<triangleCount {
            let i0 = indices[t * 3]
            let i1 = indices[t * 3 + 1]
            let i2 = indices[t * 3 + 2]
            edgeCount[Edge(i0, i1), default: 0] += 1
            edgeCount[Edge(i1, i2), default: 0] += 1
            edgeCount[Edge(i2, i0), default: 0] += 1
        }

        // Collect boundary edges (shared by only 1 triangle)
        var adjacency: [Int16: [Int16]] = [:]
        for (edge, count) in edgeCount where count == 1 {
            adjacency[edge.a, default: []].append(edge.b)
            adjacency[edge.b, default: []].append(edge.a)
        }

        guard !adjacency.isEmpty else { return [] }

        // Walk ALL boundary chains to capture head outline + features
        var allChains: [[Int16]] = []
        var globalVisited: Set<Int16> = []

        for startVertex in adjacency.keys.sorted() {
            guard !globalVisited.contains(startVertex) else { continue }

            var chain: [Int16] = [startVertex]
            var visited: Set<Int16> = [startVertex]
            var current = startVertex

            while let neighbors = adjacency[current] {
                if let next = neighbors.first(where: { !visited.contains($0) }) {
                    chain.append(next)
                    visited.insert(next)
                    current = next
                } else {
                    break
                }
            }

            globalVisited.formUnion(visited)
            if chain.count >= 5 {
                allChains.append(chain)
            }
        }

        // Sort by length descending — longest chain (head outline) first
        allChains.sort { $0.count > $1.count }

        return allChains.map { chain in
            chain.map { idx in
                let v = verts[Int(idx)]
                return CGPoint(x: CGFloat(v.x), y: CGFloat(v.y))
            }
        }
    }
}
