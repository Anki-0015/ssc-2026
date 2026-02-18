//
//  HomeView.swift
//  PocketPrep
//
//  Competition-level home dashboard
//  Animated stats, gradients, tips, active lists
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var listsViewModel: ListsViewModel
    @State private var animateStats = false
    @State private var selectedTip: Int?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    headerSection
                    
                    // Stats
                    statsGrid
                    
                    // Active Lists
                    if !listsViewModel.customLists.isEmpty {
                        activeListsSection
                    }
                    
                    // Tips
                    tipsSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PocketPrep")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateStats = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: greetingColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(greetingSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            StatCard(
                icon: "checklist",
                label: "Total Lists",
                value: "\(listsViewModel.lists.count)",
                color: .blue,
                animate: animateStats
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                label: "Items Packed",
                value: "\(listsViewModel.totalPackedItems)",
                color: .green,
                animate: animateStats
            )
            
            StatCard(
                icon: "doc.on.doc.fill",
                label: "Templates",
                value: "\(listsViewModel.templates.count)",
                color: .orange,
                animate: animateStats
            )
            
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                label: "Completion",
                value: "\(listsViewModel.overallCompletionPercentage)%",
                color: .purple,
                animate: animateStats
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Active Lists
    
    private var activeListsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Lists")
                .font(.title3.bold())
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(listsViewModel.customLists.prefix(6)) { list in
                        NavigationLink(destination: ListDetailView(list: list, viewModel: listsViewModel)) {
                            ActiveListCard(list: list)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Tips
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Packing Tips")
                .font(.title3.bold())
                .padding(.horizontal, 20)
            
            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                TipCard(tip: tip, index: index)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Computed
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌅"
        default: return "Good Night 🌙"
        }
    }
    
    private var greetingSubtitle: String {
        let packed = listsViewModel.totalPackedItems
        let total = listsViewModel.totalItems
        if total == 0 { return "Start by creating your first packing list!" }
        if packed == total { return "All packed! You're ready to go! 🎉" }
        return "\(total - packed) items left to pack across your lists"
    }
    
    private var greetingColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return [Color(hex: "#f093fb") ?? .pink, Color(hex: "#f5576c") ?? .red]
        case 12..<17: return [Color(hex: "#4facfe") ?? .blue, Color(hex: "#00f2fe") ?? .cyan]
        case 17..<21: return [Color(hex: "#fa709a") ?? .pink, Color(hex: "#fee140") ?? .yellow]
        default: return [Color(hex: "#667eea") ?? .indigo, Color(hex: "#764ba2") ?? .purple]
        }
    }
    
    private let tips: [(icon: String, title: String, detail: String)] = [
        ("lightbulb.fill", "Roll, Don't Fold", "Rolling clothes saves 30% more space than folding and reduces wrinkles."),
        ("cube.box.fill", "Use Packing Cubes", "Organize items by category for quick access and efficient packing."),
        ("list.clipboard.fill", "Pack Night Before", "Prepare your bag the evening before to avoid morning rush."),
        ("scalemass.fill", "Weigh Your Bag", "Check airline limits to avoid surprise fees at the airport.")
    ]
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.gradient)
                    )
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: color.opacity(0.1), radius: 8, y: 4)
        )
        .scaleEffect(animate ? 1 : 0.85)
        .opacity(animate ? 1 : 0)
    }
}

// MARK: - Active List Card

struct ActiveListCard: View {
    let list: PackingList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(list.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: list.icon)
                        .font(.system(size: 20))
                        .foregroundColor(list.color)
                }
                
                Spacer()
                
                Text("\(Int(list.progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(list.progress == 1 ? .green : .secondary)
            }
            
            Text(list.name)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(list.color.gradient)
                        .frame(width: geo.size.width * CGFloat(list.progress), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(list.packedCount)/\(list.totalCount) items")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(width: 170)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Tip Card

struct TipCard: View {
    let tip: (icon: String, title: String, detail: String)
    let index: Int
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(tip.detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                    .frame(width: 32)
                
                Text(tip.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
