//
//  OnboardingView.swift
//  PocketPrep
//
//  Beautiful 3-page onboarding experience
//  Shows only once, stored in @AppStorage
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var animateIcons = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: currentPage)
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "bag.fill",
                        iconColor: .blue,
                        title: "Smart Packing",
                        subtitle: "Never forget an essential item again. Organize your packing with intelligent lists.",
                        secondaryIcon: "checkmark.circle.fill"
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "list.bullet.rectangle.portrait.fill",
                        iconColor: .green,
                        title: "Pre-Built Templates",
                        subtitle: "Start with expertly curated lists for College, Gym, Travel, Camping & more.",
                        secondaryIcon: "doc.on.doc.fill"
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "AI-Powered Suggestions",
                        subtitle: "Tell our AI assistant what you're packing for and get personalized item suggestions instantly.",
                        secondaryIcon: "brain.head.profile"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == currentPage ? 28 : 8, height: 8)
                            .animation(.easeOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Button
                Button {
                    if currentPage < 2 {
                        withAnimation(.easeOut(duration: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == 2 ? "Get Started" : "Continue")
                            .font(.headline)
                        
                        Image(systemName: currentPage == 2 ? "arrow.right" : "chevron.right")
                            .font(.headline)
                    }
                    .foregroundColor(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(.white)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                
                // Skip
                if currentPage < 2 {
                    Button("Skip") {
                        withAnimation(.easeOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 24)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }
    
    private var gradientColors: [Color] {
        switch currentPage {
        case 0: return [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple]
        case 1: return [Color(hex: "#11998e") ?? .green, Color(hex: "#38ef7d") ?? .mint]
        case 2: return [Color(hex: "#6366f1") ?? .indigo, Color(hex: "#ec4899") ?? .pink]
        default: return [.blue, .purple]
        }
    }
    
    private var buttonTextColor: Color {
        switch currentPage {
        case 0: return Color(hex: "#667eea") ?? .blue
        case 1: return Color(hex: "#11998e") ?? .green
        case 2: return Color(hex: "#6366f1") ?? .indigo
        default: return .blue
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let secondaryIcon: String
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated icon
            ZStack {
                // Glow ring
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 160, height: 160)
                
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, options: .repeating)
                
                // Floating secondary icon
                Image(systemName: secondaryIcon)
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.8))
                    .offset(x: 60, y: -60)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}
