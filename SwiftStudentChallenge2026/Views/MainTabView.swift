//
//  MainTabView.swift
//  PocketPrep
//
//  Root tab view with onboarding gate
//  Competition-level with badge + shared data
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var listsViewModel = ListsViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    HomeView(listsViewModel: listsViewModel, selectedTab: $selectedTab)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    ListsView(viewModel: listsViewModel)
                        .tabItem {
                            Label("My Lists", systemImage: "checklist")
                        }
                        .badge(!listsViewModel.customLists.isEmpty && listsViewModel.totalUnpackedItems > 0 ? listsViewModel.totalUnpackedItems : 0)
                        .tag(1)
                    
                    AIAssistantView(listsViewModel: listsViewModel)
                        .tabItem {
                            Label("AI Assistant", systemImage: "sparkles")
                        }
                        .tag(2)
                    
                    SettingsView(listsViewModel: listsViewModel)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(3)
                }
                .tint(Color(hex: "#764ba2") ?? .purple)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        .onAppear {
            listsViewModel.configure(with: modelContext)
        }
    }
}
