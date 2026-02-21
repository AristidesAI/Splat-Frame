import SwiftUI

/// Full-screen dark overlay with a centered spinner shown on app launch.
/// Fades out smoothly once ARKit begins tracking.
struct LaunchOverlay: View {
    let isReady: Bool
    @State private var opacity: Double = 1.0
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.8))
                    .scaleEffect(1.4)
            }
            .opacity(opacity)
            .allowsHitTesting(false)
            .onChange(of: isReady) { _, ready in
                if ready {
                    withAnimation(.easeOut(duration: 0.6)) {
                        opacity = 0
                    }
                    // Remove from hierarchy after animation completes
                    Task {
                        try? await Task.sleep(for: .milliseconds(700))
                        dismissed = true
                    }
                }
            }
        }
    }
}
