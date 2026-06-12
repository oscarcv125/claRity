import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            // logica
            GeometryReader { geo in
                Circle()
                    .fill(Color.menta.opacity(0.3))
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: isAnimating ? -40 : 40, y: isAnimating ? -60 : 20)
                
                Circle()
                    .fill(Color.clarityTeal.opacity(0.3))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 80)
                    .offset(x: isAnimating ? geo.size.width * 0.4 : geo.size.width * 0.2, y: isAnimating ? geo.size.height * 0.6 : geo.size.height * 0.8)
                
                Circle()
                    .fill(Color.moradoPrincipal.opacity(0.2))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 60)
                    .offset(x: isAnimating ? geo.size.width * 0.1 : -20, y: isAnimating ? geo.size.height * 0.3 : geo.size.height * 0.5)
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "sparkles",
                        title: "Bienvenido a ClaRity",
                        description: "Tu asistente de lectura inteligente diseñado para que leas y aprendas a tu propio ritmo sin distracciones.",
                        color: .clarityTeal
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "waveform",
                        title: "Lee a tu Ritmo",
                        description: "Escucha los textos mientras lees. Toca cualquier palabra dos veces para separarla en sílabas y escucharla lentamente.",
                        color: .menta
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "brain.head.profile",
                        title: "Comprende Todo",
                        description: "Toca cualquier palabra para ver su definición, o usa la Inteligencia Artificial para resumir el texto y responder preguntas.",
                        color: .moradoPrincipal
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Button {
                    withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                        if currentPage < 2 {
                            currentPage += 1
                        } else {
                            hasSeenOnboarding = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                } label: {
                    Text(currentPage < 2 ? "Siguiente" : "¡Comenzar!")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: currentPage < 2 ? [.clarityTeal, .clarityBlue] : [.moradoPrincipal, .azulPrincipal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: (currentPage < 2 ? Color.clarityTeal : Color.moradoPrincipal).opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .animation(.spring(duration: 0.4), value: currentPage)
            }
        }
    }
}


private struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, options: .repeating, value: appear)
            }
            .shadow(color: color.opacity(0.2), radius: 20, y: 10)
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                appear = true
            }
        }
    }
}


private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
