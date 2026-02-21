<p align="center">
  <img src="Splat%20Frame/Assets.xcassets/AppIcon.appiconset/splat-iOS-Default-1024x1024@1x.png" width="180" alt="Splat Frame App Icon" style="border-radius: 28%;">
</p>

<h1 align="center">Splat Frame</h1>

<p align="center">
  <strong>Turn your iPhone into a window to another dimension.</strong>
</p>

<p align="center">
  <a href="https://aristidesai.github.io/Splat-Frame/">
    <img src="https://img.shields.io/badge/Website-Splat%20Frame-6e5cff?style=for-the-badge&logo=safari&logoColor=white" alt="Website">
  </a>
  &nbsp;
  <a href="#">
    <img src="https://img.shields.io/badge/Download_on_the-App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white" alt="App Store">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS_26+-000?logo=apple&logoColor=white" alt="Platform">
  <a href="https://www.swift.org"><img src="https://img.shields.io/badge/Swift-5.0_|_Swift_6_Concurrency-F05138?logo=swift&logoColor=white" alt="Swift"></a>
  <a href="https://developer.apple.com/metal/"><img src="https://img.shields.io/badge/Metal-GPU_Rendered-8A8A8A?logo=apple&logoColor=white" alt="Metal"></a>
  <a href="https://developer.apple.com/arkit/"><img src="https://img.shields.io/badge/ARKit-Face_Tracking-00C7BE?logo=apple&logoColor=white" alt="ARKit"></a>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License">
</p>

---

<p align="center">
  <em>Real-time head-tracked parallax depth illusion — like peering through a portal on your phone.</em>
</p>

<br>

## What Is Splat Frame?

Splat Frame uses your iPhone's **TrueDepth front-facing camera** to track your head position in real time and creates a **3D parallax "window" effect** — the perspective inside the screen shifts naturally as you move, making it look like you're looking through a real portal into a 3D room.

Place your **photos and videos** from your photo library onto the 5 inner walls of the room. Move your head. Watch them come alive.

> The same off-axis projection math used in real 3D window displays and museum installations — running at 60fps on your iPhone.

<br>

## The Effect

```
         ┌─────────────────────┐
         │     ╔═══════════╗   │
         │    ╱│  ceiling  │╲  │
         │   ╱ ╚═══════════╝ ╲ │
         │  │left│  back  │right│
         │   ╲ ╔═══════════╗ ╱ │
         │    ╲│   floor   │╱  │
         │     ╚═══════════╝   │
         └─────────────────────┘
             Your iPhone Screen

     Move your head → perspective shifts
     Like looking through a real window
```

<br>

## Features

| Feature | Description |
|---|---|
| **Photo & Video Walls** | Place media from your library on any of the 5 cube faces |
| **Cube or Portrait** | Switch between square and tall rectangular room shapes |
| **Real-Time Head Tracking** | ARKit face tracking at 60fps for precise parallax |
| **Gyroscope Tracking** | Phone tilt also drives the perspective — works together with face tracking |
| **Adjustable Sensitivity** | Fine-tune smoothing, movement scale, and gyro sensitivity |
| **Physics Effects** | Wobble/jello, inertia/slide, and bounce effects on the cube and wireframe edges |
| **Screen Recording** | Built-in recording to capture and share your creations |
| **Pinch to Zoom** | Scale the room depth to your preference |
| **One-Tap Calibration** | Reset head tracking origin instantly |

<br>

## How It Works

```
┌──────────────────┐    ┌────────────────────┐    ┌──────────────────┐
│   TrueDepth      │    │  Off-Axis           │    │   SceneKit       │
│   Camera          │───▶│  Projection         │───▶│   Renderer       │
│                    │    │                      │    │                  │
│  ARKit face       │    │  Asymmetric frustum  │    │  5-plane room    │
│  tracking         │    │  from head position  │    │  + camera        │
│  (x, y, z)        │    │  (like a real        │    │  override        │
│                    │    │   3D window)         │    │  @ 60fps Metal   │
└──────────────────┘    └────────────────────┘    └──────────────────┘
         ▲                                                  │
         │              ┌────────────────────┐              │
         └──────────────│  Gyroscope +        │◀─────────── │
                        │  Motion Effects    │
                        │  (wobble, inertia, │
                        │   bounce)           │
                        └────────────────────┘
```

The parallax illusion uses an **asymmetric frustum** — the projection shifts inversely to your head movement:

```swift
nearOverDist = near / headZ
left   = (-halfScreenWidth  - headX) × nearOverDist
right  = ( halfScreenWidth  - headX) × nearOverDist
bottom = (-halfScreenHeight - headY) × nearOverDist
top    = ( halfScreenHeight - headY) × nearOverDist
```

<br>

## Requirements

| Requirement |
|---|
| iPhone X or later (TrueDepth camera required) |
| iOS 26+ |
| Xcode 26.2+ to build from source |

<br>

## Tech Stack

<p align="center">
  <a href="https://developer.apple.com/xcode/swiftui/"><img src="https://img.shields.io/badge/SwiftUI-Declarative_UI-007AFF?style=flat-square&logo=swift&logoColor=white"></a>
  <a href="https://developer.apple.com/scenekit/"><img src="https://img.shields.io/badge/SceneKit-3D_Scene-34C759?style=flat-square&logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/arkit/"><img src="https://img.shields.io/badge/ARKit-Face_Tracking-FF9500?style=flat-square&logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/metal/"><img src="https://img.shields.io/badge/Metal-GPU_Rendering-8E8E93?style=flat-square&logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/documentation/coremotion"><img src="https://img.shields.io/badge/CoreMotion-Gyroscope-5856D6?style=flat-square&logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/documentation/replaykit"><img src="https://img.shields.io/badge/ReplayKit-Recording-FF2D55?style=flat-square&logo=apple&logoColor=white"></a>
</p>

<br>

## Open Source Libraries

Splat Frame is built on top of these open source packages:

| Package | Description | Link |
|---|---|---|
| **MetalSplatter** | High-performance Gaussian splat renderer for Metal. Provides `SplatRenderer`, `SplatChunk`, and scene file I/O. | [scier/MetalSplatter](https://github.com/scier/MetalSplatter) |
| **spz-swift** | Swift bindings for the `.spz` compressed splat format — fast loading of Gaussian splat files on Apple platforms. | [scier/spz-swift](https://github.com/scier/spz-swift) |
| **swift-argument-parser** | Apple's library for straightforward, type-safe command-line argument parsing in Swift. Transitive dependency of MetalSplatter. | [apple/swift-argument-parser](https://github.com/apple/swift-argument-parser) |

All packages are managed via **Swift Package Manager**.

<br>

## License

This project is open source. See the [LICENSE](LICENSE) file for details.

<br>

## Links

<p align="center">
  <a href="https://aristidesai.github.io/Splat-Frame/">Website</a>
  &nbsp;·&nbsp;
  <a href="#">App Store</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/aristidesai/Splat-Frame/issues">Report Bug</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/aristidesai/Splat-Frame/issues">Request Feature</a>
</p>

---

<p align="center">
  <sub>Built with off-axis projection math</sub>
</p>
