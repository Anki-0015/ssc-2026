//
//  ConfettiView.swift
//  PocketPrep
//
//  Canvas-based confetti particle system
//  Celebrates when a packing list reaches 100%
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let age = time - particle.creationTime
                    guard age < particle.lifetime else { continue }
                    
                    let progress = age / particle.lifetime
                    let opacity = 1.0 - progress
                    
                    // Physics
                    let x = particle.startX + particle.velocityX * age
                    let y = particle.startY + particle.velocityY * age + 0.5 * 400 * age * age // gravity
                    let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * age * 60)
                    
                    guard x > -20, x < size.width + 20, y < size.height + 20 else { continue }
                    
                    context.opacity = opacity
                    
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: x, y: y)
                    transform = transform.rotated(by: rotation.radians)
                    
                    context.transform = transform
                    
                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * (particle.isSquare ? 1 : 0.4)
                    )
                    
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: particle.isSquare ? 2 : 1),
                        with: .color(particle.color)
                    )
                    
                    context.transform = .identity
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            burst()
        }
    }
    
    private func burst() {
        let now = Date().timeIntervalSinceReferenceDate
        var newParticles: [ConfettiParticle] = []
        
        for _ in 0..<80 {
            let particle = ConfettiParticle(
                startX: UIScreen.main.bounds.width / 2 + Double.random(in: -80...80),
                startY: -20,
                velocityX: Double.random(in: -200...200),
                velocityY: Double.random(in: -600 ... -200),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -8...8),
                size: Double.random(in: 6...14),
                color: colors.randomElement() ?? .blue,
                lifetime: Double.random(in: 2.5...4.5),
                creationTime: now + Double.random(in: 0...0.3),
                isSquare: Bool.random()
            )
            newParticles.append(particle)
        }
        
        particles = newParticles
    }
}

struct ConfettiParticle {
    let startX: Double
    let startY: Double
    let velocityX: Double
    let velocityY: Double
    let rotation: Double
    let rotationSpeed: Double
    let size: Double
    let color: Color
    let lifetime: Double
    let creationTime: Double
    let isSquare: Bool
}
