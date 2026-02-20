//
//  SettingsView.swift
//  PocketPrep
//
//  Premium settings & about screen
//  User name, data management, app credits
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var listsViewModel: ListsViewModel
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    @State private var showClearConfirmation = false
    @State private var showResetOnboarding = false
    @State private var showClearedToast = false
    @AppStorage("appearanceMode") private var appearanceMode = 0 // 0=System, 1=Light, 2=Dark
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#667eea") ?? .blue,
                                            Color(hex: "#764ba2") ?? .purple
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            Text(userInitials)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName.isEmpty ? "PocketPrep User" : userName)
                                .font(.headline)
                            Text("Personalize your experience")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Label("Your Name", systemImage: "person.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("Enter your name", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats Section
                Section("Your Stats") {
                    StatRow(icon: "checklist", color: .blue, label: "Total Lists", value: "\(listsViewModel.lists.count)")
                    StatRow(icon: "checkmark.circle.fill", color: .green, label: "Items Packed", value: "\(listsViewModel.totalPackedItems)")
                    StatRow(icon: "chart.line.uptrend.xyaxis", color: .purple, label: "Completion", value: "\(listsViewModel.overallCompletionPercentage)%")
                    StatRow(icon: "tray.full.fill", color: .orange, label: "Total Items", value: "\(listsViewModel.totalItems)")
                }
                
                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceMode) {
                        Label("System", systemImage: "gear").tag(0)
                        Label("Light", systemImage: "sun.max.fill").tag(1)
                        Label("Dark", systemImage: "moon.fill").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                // Data Management
                Section("Data Management") {
                    Button {
                        showResetOnboarding = true
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.primary)
                    }
                    
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Lists", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Built With", systemImage: "swift")
                        Spacer()
                        Text("SwiftUI & SwiftData")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("AI Engine", systemImage: "sparkles")
                        Spacer()
                        Text("Apple Intelligence")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Platform", systemImage: "ipad")
                        Spacer()
                        Text("iPad · iOS 26+")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Credits
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("PocketPrep")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text("Swift Student Challenge 2026")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(.systemGray6)))
                        
                        Text("Your smart packing companion.\nPowered by on-device AI for complete privacy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Settings")
            .alert("Replay Onboarding?", isPresented: $showResetOnboarding) {
                Button("Cancel", role: .cancel) {}
                Button("Replay") {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasCompletedOnboarding = false
                    }
                }
            } message: {
                Text("This will show the onboarding walkthrough again.")
            }
            .alert("Clear All Lists?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearAllLists()
                }
            } message: {
                Text("This will permanently delete all your custom lists and items. Templates will be re-created.")
            }
            .overlay {
                if showClearedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("All lists cleared")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                        )
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    private var userInitials: String {
        if userName.isEmpty { return "PP" }
        let parts = userName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(userName.prefix(2)).uppercased()
    }
    
    private func clearAllLists() {
        let customLists = listsViewModel.customLists
        for list in customLists {
            listsViewModel.deleteList(list)
        }
        
        withAnimation(.easeOut(duration: 0.3)) {
            showClearedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showClearedToast = false
            }
        }
        
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.gradient)
                )
            
            Text(label)
            
            Spacer()
            
            Text(value)
                .font(.body.bold())
                .foregroundColor(.secondary)
        }
    }
}
