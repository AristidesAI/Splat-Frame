import SwiftUI

/// Full-screen gaussian splat viewer with head tracking and overlay controls.
struct SplatPlayerView: View {
    let fileURL: URL
    let headTracker: HeadTrackingService

    @State private var controller: SplatRenderController?
    @State private var loadError: String?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let controller {
                SplatRenderView(controller: controller)
                    .ignoresSafeArea()

                // Calibration button
                CalibrationOverlay(headTracker: headTracker)
            }

            if isLoading {
                ProgressView {
                    Text(controller?.loadingProgress ?? "Loading...")
                        .font(.caption)
                }
            }

            if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(loadError)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .background(.black)
        .task {
            await loadSplat()
        }
    }

    private func loadSplat() async {
        guard let ctrl = SplatRenderController() else {
            loadError = "Failed to initialize Metal renderer"
            isLoading = false
            return
        }

        controller = ctrl

        // Wire head tracking
        let tracker = headTracker
        // Update head position on timer for render thread
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            ctrl.headPosition = tracker.currentPosition
        }

        do {
            try await ctrl.loadFile(at: fileURL)
            isLoading = false
        } catch {
            loadError = "Failed to load: \(error.localizedDescription)"
            isLoading = false
            timer.invalidate()
        }
    }
}
