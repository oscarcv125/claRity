import SwiftUI

// docs
struct ConfettiView: View {
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let colors: [Color] = [.clarityTeal, .clarityBlue, .clarityCyan, .yellow, .orange]

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSince(start)
                    guard t < 2.5 else { return }
                    var rng = SeededRandom(seed: 42)
                    for i in 0..<60 {
                        let x = Double.random(in: 0...size.width, using: &rng)
                        let speed = Double.random(in: 180...420, using: &rng)
                        let drift = Double.random(in: -40...40, using: &rng)
                        let spin = Double.random(in: 0...(2 * .pi), using: &rng)
                        let y = -20 + t * speed
                        guard y < size.height + 20 else { continue }

                        var piece = ctx
                        piece.translateBy(x: x + drift * t, y: y)
                        piece.rotate(by: .radians(spin + t * 4))
                        let rect = CGRect(x: -4, y: -2.5, width: 8, height: 5)
                        piece.fill(
                            Path(roundedRect: rect, cornerRadius: 2),
                            with: .color(colors[i % colors.count].opacity(max(0, 1.0 - t / 2.5)))
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }
}

// docs
private struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &*= 2862933555777941757
        state &+= 3037000493
        return state
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ConfettiView()
    }
}
