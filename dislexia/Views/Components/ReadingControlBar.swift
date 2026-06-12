import SwiftUI

struct ReadingControlBar: View {
    let isPlaying: Bool
    @Binding var speed: Double
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            speedRow
            playbackRow
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.1), radius: 10, y: -4)
    }

    private var speedRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "tortoise.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)

            Slider(value: $speed, in: 0.1...0.6, step: 0.05)
                .accessibilityLabel("Velocidad de lectura")
                .accessibilityValue(speedLabel)

            Image(systemName: "hare.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
    }

    private var playbackRow: some View {
        HStack(spacing: 28) {
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Detener lectura")

            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .scaleEffect(isPlaying ? 1.05 : 1.0)
                    .animation(reduceMotion ? .none : .spring(duration: 0.25), value: isPlaying)
            }
            .frame(minWidth: 56, minHeight: 56)
            .accessibilityLabel(isPlaying ? "Pausar lectura" : "Reproducir lectura")

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .frame(minWidth: 44, minHeight: 44)
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
