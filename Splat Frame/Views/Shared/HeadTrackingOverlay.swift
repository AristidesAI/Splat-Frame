import SwiftUI

/// Draws head outline + feature contours from ARKit face mesh boundary chains.
struct HeadTrackingOverlay: View {
    var headTracker: HeadTrackingService

    var body: some View {
        let active = headTracker.isTracking
        let hx = CGFloat(headTracker.currentPosition.x)
        let hy = CGFloat(headTracker.currentPosition.y)
        let hz = CGFloat(headTracker.currentPosition.z)
        let contours = headTracker.faceContours

        GeometryReader { geo in
            if active && !contours.isEmpty {
                let cx = geo.size.width / 2 + (-hx) * 300
                let cy = geo.size.height * 0.35 + (-hy) * 300

                let baseScale: CGFloat = 1500
                let distFactor = 0.4 / max(0.1, hz)
                let scale = baseScale * distFactor

                let mappedContours = contours.map { contour in
                    contour.map { pt in
                        CGPoint(
                            x: cx + pt.x * scale * (-1),
                            y: cy - pt.y * scale
                        )
                    }
                }

                MultiContourShape(contours: mappedContours)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Draws smooth closed contours using Catmull-Rom → cubic Bezier.
private struct MultiContourShape: Shape {
    let contours: [[CGPoint]]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        for points in contours where points.count >= 3 {
            let n = points.count
            p.move(to: points[0])

            for i in 0..<n {
                let p0 = points[(i - 1 + n) % n]
                let p1 = points[i]
                let p2 = points[(i + 1) % n]
                let p3 = points[(i + 2) % n]

                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) / 6,
                    y: p1.y + (p2.y - p0.y) / 6
                )
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) / 6,
                    y: p2.y - (p3.y - p1.y) / 6
                )
                p.addCurve(to: p2, control1: cp1, control2: cp2)
            }
            p.closeSubpath()
        }
        return p
    }
}
