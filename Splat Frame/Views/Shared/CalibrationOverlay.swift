import SwiftUI

/// Compact head tracking status indicator.
struct CalibrationOverlay: View {
    var headTracker: HeadTrackingService

    var body: some View {
        Image(systemName: headTracker.isTracking ? "face.smiling" : "face.dashed")
            .font(.callout)
            .foregroundStyle(headTracker.isTracking ? .green.opacity(0.7) : .red.opacity(0.7))
            .padding(12)
            .glassEffect(.regular)
            .animation(.easeInOut(duration: 0.3), value: headTracker.isTracking)
    }
}
