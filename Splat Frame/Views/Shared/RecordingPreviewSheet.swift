import ReplayKit
import SwiftUI

/// Wraps RPPreviewViewController in a SwiftUI-presentable sheet.
struct RecordingPreviewSheet: UIViewControllerRepresentable {
    let previewController: RPPreviewViewController

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> RPPreviewViewController {
        previewController.previewControllerDelegate = context.coordinator
        return previewController
    }

    func updateUIViewController(_ uiViewController: RPPreviewViewController, context: Context) {}

    final class Coordinator: NSObject, RPPreviewViewControllerDelegate {
        nonisolated func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            Task { @MainActor in
                previewController.dismiss(animated: true)
            }
        }

        nonisolated func previewController(
            _ previewController: RPPreviewViewController,
            didFinishWithActivityTypes activityTypes: Set<String>
        ) {
            Task { @MainActor in
                previewController.dismiss(animated: true)
            }
        }
    }
}
