# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Splat Frame is an iOS app that creates a "window into 3D space" illusion using real-time head tracking. The front-facing TrueDepth camera tracks head position via ARKit, and an off-axis (asymmetric frustum) projection shifts the rendered perspective accordingly.

**Two main 3D experiences:**
1. **Parallax Cube** — A 3D room with 5 inner faces where users place photos/videos from their library
2. **Gaussian Splat Viewer** — Full-screen splat rendering using MetalSplatter, with head-tracked camera

**Third tab:** Instagram-like feed scraped from splats.com for discovering and downloading splat content.

## Build & Run

- **Xcode:** 26.2+ (iOS 26 SDK)
- **Target:** iOS 26.2
- **Device required:** iPhone with TrueDepth camera (face tracking does not work in Simulator)
- **Metal Toolchain:** Required for MetalSplatter shader compilation. Install with: `xcodebuild -downloadComponent MetalToolchain`
- **Build:**
  ```
  xcodebuild -project "Splat Frame.xcodeproj" -scheme "Splat Frame" -destination 'generic/platform=iOS' build
  ```
- **Bundle ID:** `aristides.lintzeris.Splat-Frame`
- **Team ID:** `8S7P33V94X`

## Swift & Concurrency

- Swift 5.0 with Swift 6 concurrency (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- All types default to `@MainActor`. Delegate callbacks from ARKit, SceneKit, and Metal fire on non-main threads — mark them `nonisolated` and dispatch state updates via `Task { @MainActor in }`.
- For hot-path data shared between render thread and main thread (e.g., `headPosition` in `SplatRenderController`), use `nonisolated(unsafe)` with single-writer/single-reader pattern.
- File System Synchronized Root Groups: new files in `Splat Frame/` auto-include in build.

## Dependencies

- **MetalSplatter** (SPM: `https://github.com/scier/MetalSplatter`) — Gaussian splat renderer
  - Products linked: `MetalSplatter`, `SplatIO`, `PLYIO`
  - Built in Swift 6 mode (compatible via SPM)
  - Key types: `SplatRenderer`, `SplatRenderer.ViewportDescriptor`, `SplatChunk`, `AutodetectSceneReader`

## Architecture

### Data Flow: Head Tracking → Projection → Rendering

```
ARKit Face Tracking (HeadTrackingService)
    → HeadPosition (x, y, z in meters, EMA-smoothed)
    → OffAxisProjection (asymmetric frustum matrix)
    → SceneKit camera (CubeSceneController) OR Metal viewport (SplatRenderController)
```

### Key Files

| Layer | File | Purpose |
|-------|------|---------|
| **Models** | `Models/HeadPosition.swift` | Head position struct (x, y, z + timestamp) |
| **Models** | `Models/AppState.swift` | Central `@Observable` state: tabs, head tracker, cube controller |
| **Models** | `Models/CubeFaceContent.swift` | `CubeFace` enum + `FaceContentType` |
| **Services** | `Services/HeadTrackingService.swift` | ARKit `ARFaceTrackingConfiguration` wrapper with EMA smoothing |
| **Services** | `Services/OffAxisProjection.swift` | Asymmetric frustum math (ported from decorate_3D_portal) |
| **Services** | `Services/ScreenCalibration.swift` | Physical screen size lookup per iPhone model |
| **Services** | `Services/SplatFeedService.swift` | HTML scraper for splats.com + feed caching |
| **Cube** | `Views/CubeMode/CubeSceneController.swift` | SceneKit scene: 5 `SCNPlane` nodes, camera projection override, content assignment |
| **Cube** | `Views/CubeMode/CubeSceneView.swift` | `UIViewRepresentable` wrapping `SCNView` |
| **Cube** | `Views/CubeMode/CubeFacePickerSheet.swift` | PhotosPicker for assigning images/videos to faces |
| **Splat** | `Views/SplatMode/SplatRenderController.swift` | `MTKViewDelegate` integrating MetalSplatter with off-axis projection |
| **Splat** | `Views/SplatMode/SplatRenderView.swift` | `UIViewRepresentable` wrapping `MTKView` |
| **Splat** | `Views/SplatMode/SplatPlayerView.swift` | Full-screen splat viewer with loading UI |
| **Feed** | `Views/SplatFeed/SplatFeedView.swift` | `LazyVGrid` of scraped thumbnails |
| **Feed** | `Views/SplatFeed/SplatFeedDetailView.swift` | Download + play flow |
| **Nav** | `Views/MainTabView.swift` | 3-tab layout (Feed, Cube, Settings) + permission gate |
| **Utils** | `Utilities/MatrixMath.swift` | `simd_float4x4` extensions: `offAxisPerspective`, `lookAt` |
| **Utils** | `Utilities/ExponentialSmoother.swift` | Generic EMA smoother for jitter reduction |

### Off-Axis Projection (core math)

The parallax illusion uses an asymmetric frustum — the projection shifts inversely to head movement:
```
nearOverDist = near / headZ
left   = (-halfScreenWidth  - headX) × nearOverDist
right  = ( halfScreenWidth  - headX) × nearOverDist
bottom = (-halfScreenHeight - headY) × nearOverDist
top    = ( halfScreenHeight - headY) × nearOverDist
```
Defined in `Services/OffAxisProjection.swift`. The `movementScale` parameter (default 1.5) exaggerates the effect.

### MetalSplatter Integration Pattern

```swift
// 1. Create renderer
let renderer = try SplatRenderer(device:, colorFormat:, depthFormat:, sampleCount:, maxViewCount:, maxSimultaneousRenders:)

// 2. Load file
let reader = try AutodetectSceneReader(url)  // handles .ply, .splat, .spz
let points = try await reader.readAll()
let chunk = try SplatChunk(device:, from: points)
await renderer.addChunk(chunk, sortByLocality: true, enabled: true)

// 3. Each frame in draw(in:)
let descriptor = SplatRenderer.ViewportDescriptor(viewport:, projectionMatrix:, viewMatrix:, screenSize:)
try renderer.render(viewports: [descriptor], colorTexture:, colorStoreAction:, depthTexture:, ..., to: commandBuffer)
```

### Info.plist Keys
- `NSCameraUsageDescription` — ARKit face tracking
- `NSPhotoLibraryUsageDescription` — Photo/video import for cube faces
