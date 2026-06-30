import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double = 1
}

struct ParticleBurstView: View {
    let origin: CGPoint
    let color: Color
    let onFinish: () -> Void

    @State private var particles: [Particle] = []
    @State private var animating = false

    var body: some View {
        Canvas { context, _ in
            for p in particles {
                let rect = CGRect(x: p.x - p.size/2, y: p.y - p.size/2,
                                  width: p.size, height: p.size)
                context.opacity = p.opacity
                context.fill(Path(ellipseIn: rect), with: .color(p.color))
            }
        }
        .allowsHitTesting(false)
        .onAppear { spawn() }
    }

    private func spawn() {
        let count = 14
        particles = (0..<count).map { i in
            let angle = Double(i) / Double(count) * .pi * 2
            let speed = CGFloat.random(in: 60...140)
            return Particle(
                x: origin.x, y: origin.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                color: color,
                size: CGFloat.random(in: 5...10)
            )
        }
        // Animate over 0.6s using display link cadence via steps
        let totalSteps = 18
        let dt: Double = 0.6 / Double(totalSteps)
        for step in 1...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + dt * Double(step)) {
                let progress = Double(step) / Double(totalSteps)
                for i in particles.indices {
                    particles[i].x += particles[i].vx * CGFloat(dt)
                    particles[i].y += particles[i].vy * CGFloat(dt)
                    particles[i].vy += 120 * CGFloat(dt) // gravity
                    particles[i].opacity = max(0, 1 - progress * 1.2)
                    particles[i].size *= 0.97
                }
                if step == totalSteps { onFinish() }
            }
        }
    }
}
