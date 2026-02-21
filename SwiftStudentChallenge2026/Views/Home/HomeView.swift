//
//  HomeView.swift
//  PocketPrep
//
//  Competition-level home dashboard
//  Progress ring, templates, active & completed lists
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var listsViewModel: ListsViewModel
    @Binding var selectedTab: Int
    @AppStorage("userName") private var userName = ""
    @State private var animateStats = false
    @State private var showNewListSheet = false
    @State private var showAllPastLists = false
    
    private var activeLists: [PackingList] {
        listsViewModel.customLists.filter { $0.progress < 1.0 }
    }
    
    private var completedLists: [PackingList] {
        listsViewModel.customLists.filter { $0.progress >= 1.0 }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Ongoing Lists
                        ongoingListsSection
                        
                        if !listsViewModel.customLists.isEmpty {
                            // Progress Hero Card
                            progressHeroCard
                        }
                        
                        // Templates
                        templatesCarousel
                        

                        
                        // Tips (only when few lists)
                        if listsViewModel.customLists.count < 3 {
                            tipsSection
                        }
                        
                        // Footer
                        motivationalFooter
                    }
                    .padding(.bottom, 100) // extra padding so content isn't hidden behind FAB
                }
                
                // Floating Add Button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showNewListSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#667eea") ?? .indigo,
                                        Color(hex: "#764ba2") ?? .purple
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: (Color(hex: "#764ba2") ?? .purple).opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PocketPrep")
            .sheet(isPresented: $showNewListSheet) {
                NewListSheet(viewModel: listsViewModel)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateStats = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: greetingColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    

    
    // MARK: - Ongoing Lists
    
    private var ongoingLists: [PackingList] {
        listsViewModel.customLists
            .filter { $0.progress < 1.0 }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var ongoingListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#667eea") ?? .blue)
                
                Text("Ongoing Lists")
                    .font(.callout.bold())
                
                if !ongoingLists.isEmpty {
                    Text("\(ongoingLists.count)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill((Color(hex: "#667eea") ?? .blue).gradient))
                }
                
                Spacer()
                
                if ongoingLists.count > 3 {
                    Button {
                        withAnimation { selectedTab = 1 }
                    } label: {
                        Text("See All")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            if ongoingLists.isEmpty {
                // Compact empty state
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No ongoing lists")
                            .font(.callout.bold())
                            .foregroundColor(.secondary)
                        Text("All caught up! Create a new list below")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(ongoingLists.prefix(3)) { list in
                        NavigationLink(destination: ListDetailView(list: list, viewModel: listsViewModel)) {
                            PastListRow(list: list)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Progress Hero Card
    
    private var progressHeroCard: some View {
        HStack(spacing: 20) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 9)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .trim(from: 0, to: animateStats ? progressValue : 0)
                    .stroke(progressGradient, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(listsViewModel.overallCompletionPercentage)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("%")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats column
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 16) {
                    MiniStat(icon: "checklist", value: "\(listsViewModel.customLists.count)", label: "Lists", color: .blue)
                    MiniStat(icon: "checkmark.circle.fill", value: "\(listsViewModel.totalPackedItems)", label: "Packed", color: .green)
                }
                
                HStack(spacing: 16) {
                    MiniStat(icon: "circle", value: "\(listsViewModel.totalUnpackedItems)", label: "Left", color: .orange)
                    MiniStat(icon: "tray.full.fill", value: "\(listsViewModel.totalItems)", label: "Total", color: .purple)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Templates
    
    private var templatesCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("Quick Start Templates")
                    .font(.callout.bold())
                
                Spacer()
                
                Button {
                    withAnimation { selectedTab = 1 }
                } label: {
                    Text("See All")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 10) {
                ForEach(listsViewModel.templates.prefix(3)) { template in
                    TemplateChip(template: template) {
                        listsViewModel.duplicateTemplate(template)
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Active Lists
    
    private var activeListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("In Progress")
                    .font(.subheadline.bold())
                
                Text("\(activeLists.count)")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.gradient))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(activeLists.prefix(8)) { list in
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
    
    // MARK: - Completed Lists
    
    private var completedListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                
                Text("Completed")
                    .font(.subheadline.bold())
                
                Text("\(completedLists.count)")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.gradient))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(completedLists.prefix(5)) { list in
                    NavigationLink(destination: ListDetailView(list: list, viewModel: listsViewModel)) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(list.color.opacity(0.15))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: list.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(list.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                
                                Text("\(list.totalCount) items packed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Tips
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.yellow)
                
                Text("Packing Tips")
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 20)
            
            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                TipCard(tip: tip, index: index)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Motivational Footer
    
    private var motivationalFooter: some View {
        VStack(spacing: 6) {
            Text(motivationalQuote.text)
                .font(.footnote.italic())
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Text("— \(motivationalQuote.author)")
                .font(.caption2.bold())
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 12)
    }
    
    // MARK: - Computed Properties
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userName.isEmpty ? "" : ", \(userName.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? userName)"
        switch hour {
        case 5..<12: return "Good Morning\(name) \u{2600}\u{FE0F}"
        case 12..<17: return "Good Afternoon\(name) \u{1F324}"
        case 17..<21: return "Good Evening\(name) \u{1F305}"
        default: return "Good Night\(name) \u{1F319}"
        }
    }
    
    private var greetingSubtitle: String {
        let packed = listsViewModel.totalPackedItems
        let total = listsViewModel.totalItems
        if listsViewModel.customLists.isEmpty { return "Start by creating your first packing list!" }
        if packed == total && total > 0 { return "\(total) items packed across \(listsViewModel.customLists.count) lists" }
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
    
    private var progressValue: CGFloat {
        let total = listsViewModel.totalItems
        guard total > 0 else { return 0 }
        return CGFloat(listsViewModel.totalPackedItems) / CGFloat(total)
    }
    
    private var progressGradient: AngularGradient {
        let percentage = listsViewModel.overallCompletionPercentage
        if percentage >= 100 {
            return AngularGradient(colors: [.green, .mint, .green], center: .center)
        } else if percentage >= 50 {
            return AngularGradient(colors: [.blue, .cyan, .blue], center: .center)
        }
        return AngularGradient(colors: [.orange, .yellow, .orange], center: .center)
    }
    
    private let tips: [(icon: String, title: String, detail: String)] = [
        ("lightbulb.fill", "Roll, Don't Fold", "Rolling clothes saves 30% more space than folding and reduces wrinkles."),
        ("cube.box.fill", "Use Packing Cubes", "Organize items by category for quick access and efficient packing."),
        ("list.clipboard.fill", "Pack Night Before", "Prepare your bag the evening before to avoid morning rush."),
        ("scalemass.fill", "Weigh Your Bag", "Check airline limits to avoid surprise fees at the airport.")
    ]
    
    private var motivationalQuote: (text: String, author: String) {
        let quotes: [(String, String)] = [
            ("A journey of a thousand miles begins with a single step.", "Lao Tzu"),
            ("The secret of getting ahead is getting started.", "Mark Twain"),
            ("Adventure is worthwhile in itself.", "Amelia Earhart"),
            ("Not all those who wander are lost.", "J.R.R. Tolkien")
        ]
        let day = Calendar.current.component(.day, from: Date())
        return quotes[day % quotes.count]
    }
}



// MARK: - Mini Stat

struct MiniStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.gradient)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 80, alignment: .leading)
    }
}

// MARK: - Template Chip

struct TemplateChip: View {
    let template: PackingList
    let onUse: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(template.color.opacity(0.18))
                    .frame(width: 48, height: 48)
                
                Image(systemName: template.icon)
                    .font(.system(size: 20))
                    .foregroundColor(template.color)
            }
            
            VStack(spacing: 3) {
                Text(template.name)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                Text("\(template.items.count) items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button {
                onUse()
            } label: {
                Text("Use")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(template.color.gradient)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: list.icon)
                        .font(.system(size: 18))
                        .foregroundColor(list.color)
                }
                
                Spacer()
                
                Text("\(Int(list.progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(list.progress >= 0.8 ? .green : .secondary)
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
                        .frame(height: 5)
                    
                    Capsule()
                        .fill(list.color.gradient)
                        .frame(width: geo.size.width * CGFloat(list.progress), height: 5)
                }
            }
            .frame(height: 5)
            
            Text("\(list.packedCount)/\(list.totalCount) items")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(width: 165)
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
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                    .frame(width: 28)
                
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

// MARK: - Past List Row

struct PastListRow: View {
    let list: PackingList
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(list.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: list.icon)
                    .font(.system(size: 16))
                    .foregroundColor(list.color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(list.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(list.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(list.totalCount) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: list.progress)
                    .stroke(list.color.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(list.progress * 100))")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - All Past Lists View (See All)

struct AllPastListsView: View {
    let lists: [PackingList]
    @ObservedObject var viewModel: ListsViewModel
    
    var body: some View {
        List {
            ForEach(lists) { list in
                NavigationLink(destination: ListDetailView(list: list, viewModel: viewModel)) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(list.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: list.icon)
                                .font(.system(size: 16))
                                .foregroundColor(list.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(list.name)
                                .font(.subheadline.bold())
                            
                            HStack(spacing: 6) {
                                Text(list.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("·")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("\(list.packedCount)/\(list.totalCount) packed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(Int(list.progress * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(list.progress >= 1.0 ? .green : .secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("All Lists")
        .navigationBarTitleDisplayMode(.inline)
    }
}
