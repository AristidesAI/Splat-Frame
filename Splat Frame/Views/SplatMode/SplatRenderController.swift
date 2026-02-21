import MetalKit
import MetalSplatter
import SplatIO
import simd

/// Manages MetalSplatter rendering with head-tracked camera.
/// Conforms to MTKViewDelegate for per-frame rendering.
final class SplatRenderController: NSObject, MTKViewDelegate, Sendable {
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let splatRenderer: SplatRenderer

    private let offAxis = OffAxisProjection()
    private let screenCalibration = ScreenCalibration.forCurrentDevice()

    /// Head position updated from main thread, read on render thread.
    /// Single-writer (main) / single-reader (render) pattern is safe for value types.
    nonisolated(unsafe) var headPosition: HeadPosition = .zero

    /// Whether splat data has been loaded
    nonisolated(unsafe) private(set) var isLoaded = false

    /// Loading state for UI
    nonisolated(unsafe) var loadingProgress: String = ""

    init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let device else { return nil }
        guard let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue

        do {
            self.splatRenderer = try SplatRenderer(
                device: device,
                colorFormat: .bgra8Unorm,
                depthFormat: .depth32Float,
                sampleCount: 1,
                maxViewCount: 1,
                maxSimultaneousRenders: 3
            )
        } catch {
            print("Failed to create SplatRenderer: \(error)")
            return nil
        }
        super.init()
    }

    /// Load a gaussian splat file (.ply, .splat, .spz) using SplatIO.
    func loadFile(at url: URL) async throws {
        loadingProgress = "Reading file..."
        isLoaded = false

        // Access security-scoped resource if needed (for files from Files app)
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let reader = try AutodetectSceneReader(url)
        var allPoints: [SplatPoint] = []

        for try await batch in try await reader.read() {
            allPoints.append(contentsOf: batch)
            loadingProgress = "Loaded \(allPoints.count) splats..."
        }

        guard !allPoints.isEmpty else {
            loadingProgress = "No splats found in file"
            return
        }

        loadingProgress = "Uploading to GPU..."
        let chunk = try SplatChunk(device: device, from: allPoints)
        _ = await splatRenderer.addChunk(chunk, sortByLocality: true, enabled: true)

        isLoaded = true
        loadingProgress = "\(allPoints.count) splats loaded"
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        guard isLoaded else { return }
        guard let drawable = view.currentDrawable else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let pos = headPosition
        let projMatrix = offAxis.projectionMatrix(headPosition: pos, screen: screenCalibration)
        let camPos = offAxis.cameraPosition(headPosition: pos)

        let viewMatrix = simd_float4x4.lookAt(
            eye: camPos,
            center: SIMD3<Float>(0, 0, -0.25),
            up: SIMD3<Float>(0, 1, 0)
        )

        let viewport = MTLViewport(
            originX: 0, originY: 0,
            width: Double(view.drawableSize.width),
            height: Double(view.drawableSize.height),
            znear: 0.0, zfar: 1.0
        )

        let descriptor = SplatRenderer.ViewportDescriptor(
            viewport: viewport,
            projectionMatrix: projMatrix,
            viewMatrix: viewMatrix,
            screenSize: SIMD2<Int>(
                Int(view.drawableSize.width),
                Int(view.drawableSize.height)
            )
        )

        do {
            let rendered = try splatRenderer.render(
                viewports: [descriptor],
                colorTexture: drawable.texture,
                colorStoreAction: .store,
                depthTexture: view.depthStencilTexture,
                rasterizationRateMap: nil,
                renderTargetArrayLength: 0,
                to: commandBuffer
            )
            if rendered {
                commandBuffer.present(drawable)
            }
        } catch {
            print("Splat render error: \(error)")
        }

        commandBuffer.commit()
    }
}
