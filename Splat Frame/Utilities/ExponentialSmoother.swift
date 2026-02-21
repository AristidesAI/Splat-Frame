/// Exponential moving average (EMA) smoother for reducing jitter in tracking data.
/// `smoothed = alpha * current + (1 - alpha) * previous`
struct ExponentialSmoother: Sendable {
    /// Smoothing factor: 0 = fully smooth (no change), 1 = no smoothing (raw values).
    /// Typical range for head tracking: 0.15–0.4
    var alpha: Float
    private var previous: Float?

    init(alpha: Float = 0.25) {
        self.alpha = alpha
    }

    mutating func smooth(_ value: Float) -> Float {
        guard let prev = previous else {
            previous = value
            return value
        }
        let result = alpha * value + (1 - alpha) * prev
        previous = result
        return result
    }

    mutating func reset() {
        previous = nil
    }
}
