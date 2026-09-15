import SwiftUI

struct WaterBreakOverlayView: View {
    @ObservedObject var timerManager: TimerManager

    @State private var appear = false
    @State private var dropletFall: CGFloat = -60
    @State private var dropletOpacity: Double = 1
    @State private var waveOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 0.9
    @State private var quote: String = HydrationQuotes.random()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                oceanBackground
                bubbles(geo: geo)
                messageView(geo: geo)
                glassView
                buttonsView
            }
            .onAppear {
                quote = HydrationQuotes.random()
                withAnimation(.easeIn(duration: 0.6)) { appear = true }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) {
                    dropletFall = 50
                    dropletOpacity = 0
                }
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    waveOffset = 1
                }
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.12
                }
            }
        }
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Layers

    // Teal/emerald "water" palette — deliberately greener and less blue-violet
    // than the eye-break screen's indigo night sky, so the two read as distinct.
    private var oceanBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.14, blue: 0.15),
                Color(red: 0.03, green: 0.22, blue: 0.21),
                Color(red: 0.05, green: 0.32, blue: 0.28),
                Color(red: 0.08, green: 0.42, blue: 0.34),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// Bubbles drift slowly upward and fade in/out on independent loops —
    /// continuous, gentle motion rather than a static scattering.
    private func bubbles(geo: GeometryProxy) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ForEach(0..<18, id: \.self) { i in
                let seed = CGFloat(i)
                let period = 7.0 + Double(i % 5) * 1.3
                let phase = (t + Double(i) * 1.7).truncatingRemainder(dividingBy: period) / period
                let x = geo.size.width * ((seed * 0.618).truncatingRemainder(dividingBy: 1))
                let startY = geo.size.height * 0.78
                let endY = geo.size.height * 0.12
                let y = startY + (endY - startY) * CGFloat(phase)
                let size: CGFloat = 4 + (seed.truncatingRemainder(dividingBy: 5))
                let fade = sin(Double.pi * phase)
                Circle()
                    .stroke(Color.white.opacity(0.20 * fade), lineWidth: 1)
                    .frame(width: size, height: size)
                    .position(x: x, y: y)
            }
        }
    }

    private func messageView(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: geo.size.height * 0.10)

            Image(systemName: "drop.fill")
                .font(.system(size: min(geo.size.width * 0.045, 40)))
                .foregroundStyle(
                    LinearGradient(colors: [Color(red: 0.55, green: 0.85, blue: 0.72), Color(red: 0.30, green: 0.62, blue: 0.55)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .opacity(0.85)
                .offset(y: dropletFall)
                .opacity(dropletOpacity)

            Text("Time for a Water Break")
                .font(.system(size: min(geo.size.width * 0.036, 48), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .padding(.top, 14)

            Text(quote)
                .font(.system(size: min(geo.size.width * 0.014, 18), weight: .medium, design: .rounded))
                .italic()
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 60)

            Spacer(minLength: 24)
            countdownRing
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 4)
                .frame(width: 90, height: 90)
            Circle()
                .trim(from: 0, to: timerManager.waterBreakDuration > 0
                      ? CGFloat(timerManager.waterBreakProgress) : 0)
                .stroke(Color(red: 0.40, green: 0.75, blue: 0.62).opacity(0.8),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerManager.waterBreakTimeRemaining)
            Text("\(Int(timerManager.waterBreakTimeRemaining))")
                .font(.system(size: 32, weight: .thin, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var glassView: some View {
        let fillFraction = timerManager.waterBreakDuration > 0 ? timerManager.waterBreakProgress : 0
        return VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .bottom) {
                // Slow-pulsing halo — the water-break equivalent of the eye-break
                // breathing circle, keeping the same calm, rhythmic motion language.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.30, green: 0.60, blue: 0.50).opacity(0.30),
                                     Color(red: 0.25, green: 0.50, blue: 0.45).opacity(0.0)],
                            center: .center, startRadius: 4, endRadius: 100
                        )
                    )
                    .frame(width: 190, height: 190)
                    .scaleEffect(pulseScale)
                    .offset(y: -20)

                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.22), lineWidth: 2.5)
                    .frame(width: 80, height: 116)

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(colors: [Color(red: 0.40, green: 0.75, blue: 0.62).opacity(0.7),
                                                 Color(red: 0.20, green: 0.50, blue: 0.45).opacity(0.55)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 74, height: max(4, 110 * CGFloat(fillFraction)))
                    .offset(x: 0, y: -3)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.linear(duration: 1), value: fillFraction)
            }
            .padding(.bottom, 42)
        }
    }

    private var buttonsView: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                actionButton("Snooze 5 min", primary: false) { timerManager.snoozeWaterBreak(minutes: 5) }
                actionButton("Drink Up!", primary: true)  { timerManager.skipWaterBreak() }
            }
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private func actionButton(_ label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(primary ? Color(red: 0.08, green: 0.14, blue: 0.16) : .white.opacity(0.85))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Capsule().fill(primary ? Color.white.opacity(0.9) : Color.white.opacity(0.10)))
        }
        .buttonStyle(.plain)
    }
}

enum HydrationQuotes {
    static let all: [String] = [
        "Drink water like it's your job — because for your body, it kind of is.",
        "A glass of water now is cheaper than a headache later.",
        "Your brain is 75% water — give it a refill.",
        "Hydration is the original energy drink.",
        "Small sips, big difference.",
        "Water: the original productivity hack.",
        "Thirsty? That means you're already behind — drink up.",
        "Every cell in your body is waiting on this glass of water.",
        "Coffee can wait. Water can't.",
        "Refill yourself before you refill your to-do list.",
        "A well-hydrated mind is a clearer mind.",
        "Take care of your body — it's the only place you have to live.",
    ]

    static func random() -> String {
        all.randomElement() ?? all[0]
    }
}
