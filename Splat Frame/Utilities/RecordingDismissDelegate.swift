import ReplayKit

/// Shared delegate that dismisses the RPPreviewViewController after save or done.
final class RecordingDismissDelegate: NSObject, RPPreviewViewControllerDelegate {
    nonisolated static let shared = RecordingDismissDelegate()

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
