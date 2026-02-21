import UIKit

/// Physical screen dimensions in meters, used by the off-axis projection math.
/// Accuracy here directly affects the quality of the parallax illusion.
struct ScreenCalibration: Sendable {
    let widthMeters: Float
    let heightMeters: Float

    /// Lookup table of physical screen sizes per device identifier.
    /// These are the active display area dimensions (not including bezels).
    static func forCurrentDevice() -> ScreenCalibration {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0)
            }
        } ?? "unknown"

        // Width x Height in millimeters (portrait orientation)
        // Source: Apple device specs
        let dimensions: (w: Float, h: Float) = switch machine {
        // iPhone 16 Pro Max
        case "iPhone17,2": (77.6, 163.0)
        // iPhone 16 Pro
        case "iPhone17,1": (71.5, 149.6)
        // iPhone 16 Plus
        case "iPhone17,4": (77.8, 160.9)
        // iPhone 16
        case "iPhone17,3": (71.6, 147.7)
        // iPhone 15 Pro Max
        case "iPhone16,2": (77.6, 163.0)
        // iPhone 15 Pro
        case "iPhone16,1": (71.5, 149.6)
        // iPhone 15 Plus
        case "iPhone15,5": (77.8, 160.9)
        // iPhone 15
        case "iPhone15,4": (71.6, 147.7)
        // iPhone 14 Pro Max
        case "iPhone15,3": (77.6, 163.0)
        // iPhone 14 Pro
        case "iPhone15,2": (71.5, 147.5)
        // iPhone 14 Plus
        case "iPhone14,8": (77.8, 160.9)
        // iPhone 14
        case "iPhone14,7": (71.6, 146.7)
        // Fallback: estimate from UIScreen
        default:
            estimateFromScreen()
        }

        return ScreenCalibration(
            widthMeters: dimensions.w / 1000.0,
            heightMeters: dimensions.h / 1000.0
        )
    }

    /// Rough estimate using UIScreen dimensions and ~460 PPI for modern iPhones.
    private static func estimateFromScreen() -> (w: Float, h: Float) {
        let screen = UIScreen.main
        let nativeWidth = Float(screen.nativeBounds.width)
        let nativeHeight = Float(screen.nativeBounds.height)
        let ppi: Float = 460
        let widthMM = (nativeWidth / ppi) * 25.4
        let heightMM = (nativeHeight / ppi) * 25.4
        return (widthMM, heightMM)
    }
}
