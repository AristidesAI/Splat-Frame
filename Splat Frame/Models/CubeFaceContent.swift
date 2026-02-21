import UIKit

enum CubeFace: String, CaseIterable, Identifiable, Sendable {
    case back, left, right, ceiling, floor
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .back: "square.fill"
        case .left: "rectangle.portrait.lefthalf.filled"
        case .right: "rectangle.portrait.righthalf.filled"
        case .ceiling: "rectangle.tophalf.filled"
        case .floor: "rectangle.bottomhalf.filled"
        }
    }
}

enum FaceContentType {
    case none
    case photo(UIImage)
    case video(URL)
}
