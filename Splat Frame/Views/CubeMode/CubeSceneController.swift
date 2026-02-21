import SceneKit
import SpriteKit
import AVFoundation
import Observation

/// Manages the SceneKit scene for the parallax 3D cube/room.
/// 5 inner planes (back, left, right, ceiling, floor) form the room interior.
/// The camera projection is overridden each frame with an asymmetric frustum
/// based on the user's head position, creating the "window" illusion.
@Observable
final class CubeSceneController: NSObject {
    enum RoomShape {
        case cube
        case portrait
    }

    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let roomContainer = SCNNode()

    // Room face nodes
    private(set) var backWall: SCNNode!
    private(set) var leftWall: SCNNode!
    private(set) var rightWall: SCNNode!
    private(set) var ceiling: SCNNode!
    private(set) var floor: SCNNode!

    // Edge wireframe nodes
    private var edgeNodes: [SCNNode] = []

    private var offAxis = OffAxisProjection()
    private let screenCalibration = ScreenCalibration.forCurrentDevice()

    // Base room dimensions in meters
    // Cube: square front face (equal width & height)
    private let cubeSize: (width: Float, height: Float, depth: Float) = (0.3, 0.3, 0.5)
    // Portrait: tall vertical rectangle
    private let portraitSize: (width: Float, height: Float, depth: Float) = (0.22, 0.42, 0.5)

    private var currentDimensions: (width: Float, height: Float, depth: Float)
    private(set) var currentShape: RoomShape = .cube
    private(set) var zoomScale: Float = 0.6
    private var baseMovementScale: Float = 1.5

    /// Reference to head tracker for per-frame updates
    weak var headTracker: HeadTrackingService?
    /// Reference to device motion service for phone-tilt parallax
    weak var deviceMotion: DeviceMotionService?
    /// Reference to motion effects service for wobble/inertia/bounce
    var motionEffects: MotionEffectsService?

    /// Whether each effect is enabled (read from AppState)
    var wobbleEnabled = false
    var inertiaEnabled = false
    var bounceEnabled = false

    /// Timestamp for computing delta time in render loop
    private var lastRenderTime: TimeInterval = 0

    /// Whether each line effect is enabled
    var lineWobbleEnabled = false
    var lineInertiaEnabled = false
    var lineBounceEnabled = false

    /// Base corner positions and edge connectivity for line effects
    private var baseCorners: [SIMD3<Float>] = []
    private var edgeCornerIndices: [(Int, Int)] = []

    /// Per-corner spring states for line effects
    private var cornerOffsets: [SIMD3<Float>] = []
    private var cornerVelocities: [SIMD3<Float>] = []
    private var lineInertiaOffsets: [SIMD3<Float>] = []
    private var lineInertiaVelocities: [SIMD3<Float>] = []
    private var lineBounceOffsets: [SIMD3<Float>] = []
    private var lineBounceVelocities: [SIMD3<Float>] = []
    private var lineEffectsWereActive = false

    /// Sensitivity multiplier (adjustable from settings)
    var movementScale: Float {
        get { baseMovementScale }
        set {
            baseMovementScale = newValue
            offAxis.movementScale = newValue
        }
    }

    override init() {
        currentDimensions = cubeSize
        super.init()
        scene.rootNode.addChildNode(roomContainer)
        setupCamera()
        buildRoom(with: currentDimensions)
        buildEdges(for: currentDimensions)
        setupLighting()
        offAxis.movementScale = baseMovementScale
        // Start zoomed out
        roomContainer.simdScale = SIMD3<Float>(1, 1, zoomScale)
    }

    // MARK: - Scene Setup

    private func setupCamera() {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.zNear = 0.001
        camera.zFar = 10
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0.4)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func buildRoom(with dims: (width: Float, height: Float, depth: Float)) {
        let halfW = dims.width / 2
        let halfH = dims.height / 2

        // Back wall — faces toward the viewer (black at 50% opacity)
        backWall = makePlane(width: dims.width, height: dims.height, color: .black, opacity: 0.5)
        backWall.position = SCNVector3(0, 0, -dims.depth)
        roomContainer.addChildNode(backWall)

        // Left wall
        leftWall = makePlane(width: dims.depth, height: dims.height, color: .black, opacity: 0.5)
        leftWall.eulerAngles.y = Float.pi / 2
        leftWall.position = SCNVector3(-halfW, 0, -dims.depth / 2)
        roomContainer.addChildNode(leftWall)

        // Right wall
        rightWall = makePlane(width: dims.depth, height: dims.height, color: .black, opacity: 0.5)
        rightWall.eulerAngles.y = -Float.pi / 2
        rightWall.position = SCNVector3(halfW, 0, -dims.depth / 2)
        roomContainer.addChildNode(rightWall)

        // Floor
        floor = makePlane(width: dims.width, height: dims.depth, color: .black, opacity: 0.5)
        floor.eulerAngles.x = -Float.pi / 2
        floor.position = SCNVector3(0, -halfH, -dims.depth / 2)
        roomContainer.addChildNode(floor)

        // Ceiling
        ceiling = makePlane(width: dims.width, height: dims.depth, color: .black, opacity: 0.5)
        ceiling.eulerAngles.x = Float.pi / 2
        ceiling.position = SCNVector3(0, halfH, -dims.depth / 2)
        roomContainer.addChildNode(ceiling)
    }

    private func makePlane(width: Float, height: Float, color: UIColor, opacity: CGFloat = 0.5) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.isDoubleSided = true
        material.lightingModel = .physicallyBased
        material.transparency = opacity
        material.transparencyMode = .aOne
        plane.firstMaterial = material
        return SCNNode(geometry: plane)
    }

    /// Build white wireframe edges along the interior corners of the cube
    private func buildEdges(for dims: (width: Float, height: Float, depth: Float)) {
        let halfW = dims.width / 2
        let halfH = dims.height / 2
        let d = dims.depth

        // Store the 8 corners for per-frame line effect animation
        baseCorners = [
            SIMD3<Float>(-halfW,  halfH, 0),       // 0: top-left (front face)
            SIMD3<Float>( halfW,  halfH, 0),       // 1: top-right (front face)
            SIMD3<Float>(-halfW, -halfH, 0),       // 2: bottom-left (front face)
            SIMD3<Float>( halfW, -halfH, 0),       // 3: bottom-right (front face)
            SIMD3<Float>(-halfW,  halfH, -d),      // 4: top-left (back wall)
            SIMD3<Float>( halfW,  halfH, -d),      // 5: top-right (back wall)
            SIMD3<Float>(-halfW, -halfH, -d),      // 6: bottom-left (back wall)
            SIMD3<Float>( halfW, -halfH, -d),      // 7: bottom-right (back wall)
        ]

        edgeCornerIndices = [
            // 4 depth edges (front to back)
            (0, 4), (1, 5), (2, 6), (3, 7),
            // 4 back wall edges
            (4, 5), (6, 7), (4, 6), (5, 7),
            // 4 front face edges (opening frame)
            (0, 1), (2, 3), (0, 2), (1, 3)
        ]

        let edgeRadius: CGFloat = 0.002 // 2mm thick edges

        for (i0, i1) in edgeCornerIndices {
            let c0 = baseCorners[i0]
            let c1 = baseCorners[i1]
            let edgeNode = makeEdge(
                from: SCNVector3(c0.x, c0.y, c0.z),
                to: SCNVector3(c1.x, c1.y, c1.z),
                radius: edgeRadius
            )
            roomContainer.addChildNode(edgeNode)
            edgeNodes.append(edgeNode)
        }

        resetLineEffectStates()
    }

    // MARK: - Public Controls

    func setRoomShape(_ shape: RoomShape) {
        guard shape != currentShape else { return }
        currentShape = shape
        let dims = shape == .cube ? cubeSize : portraitSize
        currentDimensions = dims
        roomContainer.childNodes.forEach { $0.removeFromParentNode() }
        edgeNodes.removeAll()
        buildRoom(with: dims)
        buildEdges(for: dims)
        roomContainer.simdScale = SIMD3<Float>(1, 1, zoomScale)
    }

    func setRoomShape(isRectangleMode: Bool) {
        setRoomShape(isRectangleMode ? .portrait : .cube)
    }

    func setZoomScale(_ scale: Float) {
        let clamped = max(0.3, min(4.0, scale))
        zoomScale = clamped
        // Scale only depth (Z axis) — front opening stays screen-sized,
        // back wall moves closer/farther to warp perceived depth.
        roomContainer.simdScale = SIMD3<Float>(1, 1, zoomScale)
    }

    private func makeEdge(from start: SCNVector3, to end: SCNVector3, radius: CGFloat) -> SCNNode {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        let length = sqrt(dx * dx + dy * dy + dz * dz)

        let cylinder = SCNCylinder(radius: radius, height: CGFloat(length))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.lightingModel = .constant
        material.emission.contents = UIColor.white
        cylinder.firstMaterial = material

        let node = SCNNode(geometry: cylinder)

        // Position at midpoint
        node.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )

        // Orient the cylinder: default axis is Y (0,1,0)
        let dirNorm = normalize(SIMD3<Float>(dx, dy, dz))
        let upVec = SIMD3<Float>(0, 1, 0)
        let cross = simd_cross(upVec, dirNorm)
        let dot = simd_dot(upVec, dirNorm)

        if simd_length(cross) < 0.0001 {
            // Parallel or anti-parallel to Y
            if dot < 0 {
                node.eulerAngles = SCNVector3(Float.pi, 0, 0)
            }
            // if dot > 0, already aligned — no rotation needed
        } else {
            let angle = acos(max(-1, min(1, dot)))
            let axis = simd_normalize(cross)
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        }

        return node
    }

    private func setupLighting() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 600
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let directional = SCNNode()
        directional.light = SCNLight()
        directional.light?.type = .directional
        directional.light?.intensity = 400
        directional.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directional)
    }

    // MARK: - Line Effects

    private func resetLineEffectStates() {
        let n = max(baseCorners.count, 8)
        cornerOffsets = Array(repeating: .zero, count: n)
        cornerVelocities = Array(repeating: .zero, count: n)
        lineInertiaOffsets = Array(repeating: .zero, count: n)
        lineInertiaVelocities = Array(repeating: .zero, count: n)
        lineBounceOffsets = Array(repeating: .zero, count: n)
        lineBounceVelocities = Array(repeating: .zero, count: n)
        lineEffectsWereActive = false
    }

    /// Reposition an edge cylinder between two displaced endpoints
    private func repositionEdge(_ node: SCNNode, from start: SIMD3<Float>, to end: SIMD3<Float>) {
        let delta = end - start
        let length = simd_length(delta)
        guard length > 0.0001 else { return }

        if let cylinder = node.geometry as? SCNCylinder {
            cylinder.height = CGFloat(length)
        }

        node.simdPosition = (start + end) / 2

        let dir = delta / length
        let up = SIMD3<Float>(0, 1, 0)
        let crossVec = simd_cross(up, dir)
        let dotVal = simd_dot(up, dir)

        if simd_length(crossVec) < 0.0001 {
            if dotVal < 0 {
                node.simdOrientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
            } else {
                node.simdOrientation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
            }
        } else {
            let angle = acos(max(-1, min(1, dotVal)))
            let axis = simd_normalize(crossVec)
            node.simdOrientation = simd_quatf(angle: angle, axis: axis)
        }
    }

    /// Per-frame line effects: wobble/jello, inertia/slide, bounce on edge vertices
    func updateLineEffects(rotationRate: SIMD3<Float>, dt: Float) {
        guard !baseCorners.isEmpty, cornerOffsets.count == baseCorners.count else { return }
        let clampedDt = min(dt, 1.0 / 30.0)
        let depth = currentDimensions.depth

        var displaced = baseCorners

        // --- Line Wobble (jello) ---
        if lineWobbleEnabled {
            let stiffness: Float = 80.0
            let damping: Float = 5.0
            let sensitivity: Float = 0.004
            let center = SIMD3<Float>(0, 0, -depth / 2)

            for i in 0..<baseCorners.count {
                let arm = baseCorners[i] - center
                // Torque-like force: corners farther from center wobble more
                let force = SIMD3<Float>(
                    rotationRate.y * arm.z - rotationRate.z * arm.y,
                    rotationRate.z * arm.x - rotationRate.x * arm.z,
                    rotationRate.x * arm.y - rotationRate.y * arm.x
                ) * sensitivity

                let spring = -stiffness * cornerOffsets[i] - damping * cornerVelocities[i] + force * 100
                cornerVelocities[i] += spring * clampedDt
                cornerOffsets[i] += cornerVelocities[i] * clampedDt
                cornerOffsets[i] = simd_clamp(cornerOffsets[i],
                                               SIMD3<Float>(repeating: -0.03),
                                               SIMD3<Float>(repeating: 0.03))
                displaced[i] += cornerOffsets[i]
            }
        } else {
            for i in 0..<cornerOffsets.count {
                cornerOffsets[i] = .zero
                cornerVelocities[i] = .zero
            }
        }

        // --- Line Inertia (sliding/shearing) ---
        if lineInertiaEnabled {
            let friction: Float = 3.5
            let sensitivity: Float = 0.003

            for i in 0..<baseCorners.count {
                // Back wall corners move more (depth factor)
                let depthFactor = abs(baseCorners[i].z) / max(depth, 0.01)
                let push = SIMD3<Float>(rotationRate.y, -rotationRate.x, 0) * sensitivity * depthFactor

                lineInertiaVelocities[i] += push
                lineInertiaVelocities[i] *= exp(-friction * clampedDt)
                lineInertiaOffsets[i] += lineInertiaVelocities[i] * clampedDt

                let maxDrift: Float = 0.04
                lineInertiaOffsets[i] = simd_clamp(lineInertiaOffsets[i],
                                                    SIMD3<Float>(repeating: -maxDrift),
                                                    SIMD3<Float>(repeating: maxDrift))
                displaced[i] += lineInertiaOffsets[i]
            }
        } else {
            for i in 0..<lineInertiaOffsets.count {
                lineInertiaOffsets[i] = .zero
                lineInertiaVelocities[i] = .zero
            }
        }

        // --- Line Bounce ---
        if lineBounceEnabled {
            let stiffness: Float = 150.0
            let damping: Float = 7.0
            let limit: Float = 0.02
            let sensitivity: Float = 0.002

            for i in 0..<baseCorners.count {
                let depthFactor = abs(baseCorners[i].z) / max(depth, 0.01)
                let push = SIMD3<Float>(rotationRate.y, -rotationRate.x, 0) * sensitivity * depthFactor
                lineBounceVelocities[i] += push

                for axis in 0...2 {
                    if lineBounceOffsets[i][axis] > limit {
                        lineBounceVelocities[i][axis] -= stiffness * (lineBounceOffsets[i][axis] - limit) * clampedDt
                    } else if lineBounceOffsets[i][axis] < -limit {
                        lineBounceVelocities[i][axis] -= stiffness * (lineBounceOffsets[i][axis] + limit) * clampedDt
                    }
                }

                lineBounceVelocities[i] *= exp(-damping * clampedDt)
                lineBounceOffsets[i] += lineBounceVelocities[i] * clampedDt

                let maxBounce: Float = 0.06
                lineBounceOffsets[i] = simd_clamp(lineBounceOffsets[i],
                                                   SIMD3<Float>(repeating: -maxBounce),
                                                   SIMD3<Float>(repeating: maxBounce))
                displaced[i] += lineBounceOffsets[i]
            }
        } else {
            for i in 0..<lineBounceOffsets.count {
                lineBounceOffsets[i] = .zero
                lineBounceVelocities[i] = .zero
            }
        }

        // Reposition all edges with displaced corners
        for (idx, (i0, i1)) in edgeCornerIndices.enumerated() where idx < edgeNodes.count {
            repositionEdge(edgeNodes[idx], from: displaced[i0], to: displaced[i1])
        }
    }

    // MARK: - Per-Frame Head Tracking Update

    func updateHeadPosition(_ position: HeadPosition) {
        // Combine head position with device tilt offset for richer parallax
        var combined = position
        if let motion = deviceMotion, motion.isActive {
            combined.x += motion.tiltOffset.x
            combined.y += motion.tiltOffset.y
        }

        let projMatrix = offAxis.projectionMatrix(headPosition: combined, screen: screenCalibration)
        cameraNode.camera?.projectionTransform = SCNMatrix4(projMatrix)

        let camPos = offAxis.cameraPosition(headPosition: combined)
        cameraNode.position = SCNVector3(camPos.x, camPos.y, camPos.z)
    }

    // MARK: - Reset

    /// Reset the cube view: center the camera and clear the head tracking origin
    func resetView() {
        zoomScale = 0.6
        roomContainer.simdScale = SIMD3<Float>(1, 1, 0.6)
        roomContainer.eulerAngles = SCNVector3(0, 0, 0)
        roomContainer.simdPosition = .zero
        cameraNode.position = SCNVector3(0, 0, 0.4)

        let defaultPosition = HeadPosition.zero
        let projMatrix = offAxis.projectionMatrix(headPosition: defaultPosition, screen: screenCalibration)
        cameraNode.camera?.projectionTransform = SCNMatrix4(projMatrix)

        resetLineEffectStates()
        // Reset edges to base positions
        for (idx, (i0, i1)) in edgeCornerIndices.enumerated() where idx < edgeNodes.count {
            repositionEdge(edgeNodes[idx], from: baseCorners[i0], to: baseCorners[i1])
        }
    }

    // MARK: - Content Assignment

    func nodeForFace(_ face: CubeFace) -> SCNNode {
        switch face {
        case .back: backWall
        case .left: leftWall
        case .right: rightWall
        case .ceiling: ceiling
        case .floor: floor
        }
    }

    func setImage(_ image: UIImage, on face: CubeFace) {
        let node = nodeForFace(face)
        let material = node.geometry?.firstMaterial ?? SCNMaterial()
        material.diffuse.contents = image
        material.transparency = 0.5
        node.geometry?.firstMaterial = material
    }

    func setVideo(_ player: AVPlayer, on face: CubeFace) {
        let node = nodeForFace(face)
        guard let plane = node.geometry as? SCNPlane else { return }

        let naturalSize = player.currentItem?.asset.tracks(withMediaType: .video).first?.naturalSize ?? CGSize(width: 1920, height: 1080)
        let isPortrait = naturalSize.height > naturalSize.width
        let sceneSize = isPortrait ? CGSize(width: 1080, height: 1920) : CGSize(width: 1920, height: 1080)

        let videoNode = SKVideoNode(avPlayer: player)
        let skScene = SKScene(size: sceneSize)
        videoNode.position = CGPoint(x: skScene.size.width / 2, y: skScene.size.height / 2)
        videoNode.size = skScene.size
        videoNode.yScale = -1 // SpriteKit Y is flipped relative to SceneKit
        skScene.addChild(videoNode)
        skScene.isPaused = false

        let material = plane.firstMaterial ?? SCNMaterial()
        material.diffuse.contents = skScene
        material.transparency = 0.5
        plane.firstMaterial = material
        player.play()
    }

    func clearFace(_ face: CubeFace) {
        let node = nodeForFace(face)
        let material = node.geometry?.firstMaterial ?? SCNMaterial()
        material.diffuse.contents = UIColor.black
        material.transparency = 0.5
        material.lightingModel = .physicallyBased
        node.geometry?.firstMaterial = material
    }
}

// MARK: - SCNSceneRendererDelegate (per-frame update)

extension CubeSceneController: SCNSceneRendererDelegate {
    nonisolated func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Read the latest head position and update the projection
        Task { @MainActor in
            guard let tracker = self.headTracker else { return }
            self.updateHeadPosition(tracker.currentPosition)

            // Compute delta time
            let dt: Float
            if self.lastRenderTime > 0 {
                dt = Float(time - self.lastRenderTime)
            } else {
                dt = Float(1.0 / 60.0)
            }
            self.lastRenderTime = time

            // Update motion effects if any are enabled
            let anyEffectActive = self.wobbleEnabled || self.inertiaEnabled || self.bounceEnabled
            if anyEffectActive, let effects = self.motionEffects, let motion = self.deviceMotion {
                let rate = motion.rotationRate
                effects.update(
                    rotationRate: rate,
                    dt: dt,
                    wobbleEnabled: self.wobbleEnabled,
                    inertiaEnabled: self.inertiaEnabled,
                    bounceEnabled: self.bounceEnabled
                )

                // Apply wobble as euler angle offsets on the room container
                var euler = SIMD3<Float>(0, 0, 0)
                if self.wobbleEnabled {
                    euler += effects.wobbleOffset
                }

                // Apply inertia + bounce as position offsets
                var posOffset = SIMD2<Float>.zero
                if self.inertiaEnabled {
                    posOffset += effects.inertiaOffset
                }
                if self.bounceEnabled {
                    posOffset += effects.bounceOffset
                }

                // Apply to room container — these are additive to the base state
                self.roomContainer.eulerAngles = SCNVector3(euler.x, euler.y, euler.z)
                self.roomContainer.simdPosition = SIMD3<Float>(posOffset.x, posOffset.y, 0)
            } else {
                // No effects — reset transforms
                self.roomContainer.eulerAngles = SCNVector3(0, 0, 0)
                self.roomContainer.simdPosition = SIMD3<Float>(0, 0, 0)
            }

            // Update line effects (per-edge vertex animation)
            let anyLineActive = self.lineWobbleEnabled || self.lineInertiaEnabled || self.lineBounceEnabled
            if anyLineActive, let motion = self.deviceMotion {
                self.updateLineEffects(rotationRate: motion.rotationRate, dt: dt)
                self.lineEffectsWereActive = true
            } else if self.lineEffectsWereActive {
                self.resetLineEffectStates()
                for (idx, (i0, i1)) in self.edgeCornerIndices.enumerated() where idx < self.edgeNodes.count {
                    self.repositionEdge(self.edgeNodes[idx], from: self.baseCorners[i0], to: self.baseCorners[i1])
                }
            }
        }
    }
}
