import SwiftUI

struct ReadingControlBar: View {
    let isPlaying: Bool
    @Binding var speed: Double
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 10) {
            speedRow
            playbackRow
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.12), radius: 20, y: -8)
    }

    // MARK: - Speed Row

    private var speedRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "tortoise.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)

            GradientSlider(value: $speed, range: 0.1...0.6, step: 0.05)
                .accessibilityLabel("Velocidad de lectura")
                .accessibilityValue(speedLabel)

            Image(systemName: "hare.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Playback Row

    private var playbackRow: some View {
        HStack(spacing: 24) {
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .frame(width: 48, height: 48)
            .accessibilityLabel("Detener lectura")

            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.semibold))
                    .scaleEffect(isPlaying ? 1.05 : 1.0)
                    .animation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6), value: isPlaying)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(.accentColor), in: Circle())
            .frame(width: 64, height: 64)
            .accessibilityLabel(isPlaying ? "Pausar lectura" : "Reproducir lectura")

            Button(action: onComplete) {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .frame(width: 48, height: 48)
            .accessibilityLabel("Marcar como leído y ver comprensión")
        }
    }

    private var speedLabel: String {
        switch speed {
        case ..<0.2:  return "Muy lento"
        case ..<0.35: return "Lento"
        case ..<0.5:  return "Normal"
        default:      return "Rápido"
        }
    }
}

// MARK: - Gradient Slider

private struct GradientSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)

                let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#7C3AED"), Color(hex: "#EC4899")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * fraction, height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: geo.size.width * fraction - 11)
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let raw = Double(drag.location.x / geo.size.width)
                        let clamped = max(0, min(1, raw))
                        let mapped = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                        let stepped = (mapped / step).rounded() * step
                        value = max(range.lowerBound, min(range.upperBound, stepped))
                    }
            )
        }
        .frame(height: 22)
    }
}

#Preview {
    @Previewable @State var speed = 0.42
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ReadingControlBar(
            isPlaying: false,
            speed: $speed,
            onPlayPause: {},
            onStop: {},
            onComplete: {}
        )
    }
}
