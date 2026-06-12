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
        // logica
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {}
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.12), radius: 20, y: -8)
    }


    private var speedRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "tortoise.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)

            SpeedSlider(value: $speed, range: 0.1...0.6, step: 0.05)
                .accessibilityLabel("Velocidad de lectura")
                .accessibilityValue(speedLabel)

            Image(systemName: "hare.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)
        }
    }


    private var playbackRow: some View {
        HStack(spacing: 24) {
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .foregroundStyle(Color.clarityBlue)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel("Detener lectura")

            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(isPlaying ? 1.05 : 1.0)
                    .animation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6), value: isPlaying)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(.clarityTeal).interactive(), in: Circle())
            .accessibilityLabel(isPlaying ? "Pausar lectura" : "Reproducir lectura")

            Button(action: onComplete) {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.menta)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
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


private struct SpeedSlider: View {
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
                    .fill(Color.clarityTeal)
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
