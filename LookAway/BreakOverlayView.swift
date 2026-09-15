import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var timerManager: TimerManager

    @State private var appear = false
    @State private var moonGlow: Double = 0.35
    @State private var breatheScale: CGFloat = 0.82
    @State private var breatheLabel = "Breathe in"
    @State private var quote: String = EyeCareQuotes.random()

    private let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, a: Double)] = [
        (0.05,0.04,1.2,0.5),(0.12,0.09,0.8,0.4),(0.20,0.03,1.1,0.45),(0.28,0.07,0.5,0.35),
        (0.37,0.05,1.3,0.5),(0.45,0.10,0.8,0.4),(0.53,0.04,1.1,0.45),(0.62,0.08,0.5,0.35),
        (0.70,0.03,1.3,0.5),(0.79,0.07,0.8,0.4),(0.87,0.05,1.1,0.45),(0.94,0.09,0.5,0.35),
        (0.08,0.16,0.8,0.35),(0.17,0.21,1.1,0.4),(0.26,0.14,0.5,0.3),(0.34,0.19,1.3,0.45),
        (0.43,0.13,0.8,0.35),(0.51,0.20,1.1,0.4),(0.60,0.15,0.5,0.3),(0.68,0.22,1.3,0.45),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                calmSky
                moonView(geo: geo)
                starsView(geo: geo)
                messageView(geo: geo)
                buttonsView
            }
            .onAppear {
                quote = EyeCareQuotes.random()
                withAnimation(.easeIn(duration: 0.6)) { appear = true }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    moonGlow = 0.55
                }
                runBreathingCycle()
            }
        }
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Breathing guide (slow, gentle — no sudden motion)

    private func runBreathingCycle() {
        withAnimation(.easeInOut(duration: 4)) {
            breatheScale = 1.15
        }
        breatheLabel = "Breathe in"
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeInOut(duration: 4)) {
                breatheScale = 0.82
            }
            breatheLabel = "Breathe out"
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                runBreathingCycle()
            }
        }
    }

    // MARK: - Layers

    private var calmSky: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.06, blue: 0.16),
                Color(red: 0.10, green: 0.08, blue: 0.22),
                Color(red: 0.14, green: 0.11, blue: 0.27),
                Color(red: 0.17, green: 0.13, blue: 0.25),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func moonView(geo: GeometryProxy) -> some View {
        Circle()
            .fill(Color(red: 0.85, green: 0.86, blue: 0.82).opacity(0.85))
            .frame(width: 56, height: 56)
            .shadow(color: Color.white.opacity(moonGlow * 0.35), radius: 26)
            .position(x: geo.size.width * 0.86, y: geo.size.height * 0.14)
    }

    /// Gentle, continuous twinkle — each star drifts its own sine wave so the
    /// sky feels alive without any single motion drawing the eye.
    private func starsView(geo: GeometryProxy) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ForEach(0..<stars.count, id: \.self) { i in
                let phase = sin(t * 0.5 + Double(i) * 0.9)
                let twinkle = 0.55 + 0.45 * (phase + 1) / 2
                Circle()
                    .fill(Color.white.opacity(stars[i].a * twinkle))
                    .frame(width: stars[i].r * 2, height: stars[i].r * 2)
                    .position(x: geo.size.width  * stars[i].x,
                              y: geo.size.height * stars[i].y * 0.65)
            }
        }
    }

    private func messageView(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: geo.size.height * 0.09)

            Text("Time to Look Away")
                .font(.system(size: min(geo.size.width * 0.036, 48), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text("Focus on something 20 feet away")
                .font(.system(size: min(geo.size.width * 0.015, 20), weight: .light))
                .foregroundColor(.white.opacity(0.55))
                .padding(.top, 8)

            Text(quote)
                .font(.system(size: min(geo.size.width * 0.014, 18), weight: .medium, design: .rounded))
                .italic()
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 60)

            Spacer(minLength: 40)
            breathingCircle
            Spacer(minLength: 20)
            countdownRing
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.35, green: 0.55, blue: 0.60).opacity(0.35),
                                 Color(red: 0.30, green: 0.45, blue: 0.55).opacity(0.05)],
                        center: .center, startRadius: 4, endRadius: 90
                    )
                )
                .frame(width: 170, height: 170)
                .scaleEffect(breatheScale)

            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                .frame(width: 120, height: 120)
                .scaleEffect(breatheScale)

            Text(breatheLabel)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .animation(nil, value: breatheLabel)
        }
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 4)
                .frame(width: 90, height: 90)
            Circle()
                .trim(from: 0, to: timerManager.breakDuration > 0
                      ? CGFloat(timerManager.breakProgress) : 0)
                .stroke(Color(red: 0.55, green: 0.75, blue: 0.78).opacity(0.8),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerManager.breakTimeRemaining)
            Text("\(Int(timerManager.breakTimeRemaining))")
                .font(.system(size: 32, weight: .thin, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var buttonsView: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                actionButton("Snooze 5 min", primary: false) { timerManager.snooze(minutes: 5) }
                actionButton("Skip Break",   primary: true)  { timerManager.skip() }
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

enum EyeCareQuotes {
    static let all: [String] = [
        "Your eyes work hardest when you least notice it — give them a moment.",
        "20 feet away, 20 seconds, and you're good to go.",
        "A short glance at the horizon resets a long stare at the screen.",
        "Rest your eyes now so they can carry you through the rest of the day.",
        "Blink. Breathe. Look away. Repeat.",
        "The best pixels are the ones you look at less often.",
        "Even a great view needs a break from being looked at.",
        "Screens don't blink for you — remember to do it yourself.",
        "A little distance now prevents a lot of strain later.",
        "Look far, see clearly, come back sharper.",
        "Your focus will thank you for this 20-second detour.",
        "The screen will wait. Your eyes shouldn't have to.",
    ]

    static func random() -> String {
        all.randomElement() ?? all[0]
    }
}
