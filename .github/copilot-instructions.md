# Project Guidelines

## Code Style
- SwiftUI-first app; keep view structs small and compose via child views near their usage (see [Splat Frame/ContentView.swift](Splat%20Frame/ContentView.swift#L9-L21)).
- Use SwiftUI app lifecycle with `@main` `App` entry (see [Splat Frame/Splat_FrameApp.swift](Splat%20Frame/Splat_FrameApp.swift#L8-L15)); prefer property wrappers/state over singletons where possible.
- Keep comments minimal; prefer self-explanatory code and clear naming.

## Architecture
- Single-target SwiftUI app. Entry point is `Splat_FrameApp` presenting `ContentView` ([Splat Frame/Splat_FrameApp.swift](Splat%20Frame/Splat_FrameApp.swift#L8-L15)).
- UI currently placeholder; planned feature from product note: front-facing camera head tracking to drive a 3D "window" depth effect for splat videos ([prd.md](prd.md)).

## Build and Test
- Open in Xcode: `xed .` from workspace root.
- Build (Debug, simulator example): `xcodebuild -scheme "Splat Frame" -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug build`
- No tests exist yet; add `xcodebuild ... test` once targets are created.

## Project Conventions
- Plan to use ARKit face tracking; gate features with `ARFaceTrackingConfiguration.isSupported` and provide a fallback UI if unavailable.
- Add camera permission copy when adding camera usage: `NSCameraUsageDescription` e.g. "SplatFrame needs camera access to track your head movement and create the 3D window effect" (not yet in Info.plist).
- Aim for smooth realtime playback of splat/portal-style videos; keep per-frame work light and prefer Metal/ARKit native pipelines over heavy CPU paths.

## Integration Points
- External references for behavior inspiration are documented in [prd.md](prd.md) (splat players and 3D portal samples).
- Future data source: browsing/downloading from splats.com; plan storage for cached videos and user media (Photos access) with explicit permission prompts.

## Security
- Camera access is sensitive; request only when needed and surface rationale in-app alongside the Info.plist string.
- When adding photo library access, use the limited-library flow where possible and avoid persisting personal media without user action.
