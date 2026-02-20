//
//  ListsView.swift
//  PocketPrep
//
//  Competition-level lists management
//  Templates, custom lists, staggered animations
//

import SwiftUI

enum ListFilter: String, CaseIterable {
    case ongoing = "Ongoing"
    case past = "Past"
}

struct ListsView: View {
    @ObservedObject var viewModel: ListsViewModel
    @State private var showNewListSheet = false
    @State private var appearAnimations: Set<UUID> = []
    @State private var searchText = ""
    @State private var showAllTemplates = false
    @State private var listToDelete: PackingList?
    @State private var showDeleteConfirmation = false
    @State private var listFilter: ListFilter = .ongoing
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Search
                    if !viewModel.lists.isEmpty {
                        SearchBar(text: $searchText)
                            .padding(.horizontal, 20)
                    }
                    
                    // Templates
                    if searchText.isEmpty {
                        templatesSection
                    }
                    
                    // Filter Picker
                    if !viewModel.customLists.isEmpty {
                        listFilterPicker
                    }
                    
                    // Custom Lists
                    customListsSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        showNewListSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showNewListSheet) {
                NewListSheet(viewModel: viewModel)
            }
            .alert("Delete List?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { listToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let list = listToDelete {
                        withAnimation { viewModel.deleteList(list) }
                        listToDelete = nil
                    }
                }
            } message: {
                if let list = listToDelete {
                    Text("\"\(list.name)\" and all its items will be permanently deleted.")
                } else {
                    Text("This list will be permanently deleted.")
                }
            }
        }
    }
    
    // MARK: - List Filter Picker
    
    private var listFilterPicker: some View {
        HStack(spacing: 0) {
            ForEach(ListFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        listFilter = filter
                        appearAnimations.removeAll()
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: filter == .ongoing ? "tray.full.fill" : "checkmark.seal.fill")
                                .font(.system(size: 12, weight: .semibold))
                            
                            Text(filter.rawValue)
                                .font(.subheadline.bold())
                            
                            let count = filter == .ongoing ? ongoingLists.count : pastLists.count
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(
                                            listFilter == filter
                                            ? (filter == .ongoing ? Color.blue : Color.green).gradient
                                            : Color.gray.gradient
                                        )
                                    )
                            }
                        }
                        .foregroundColor(listFilter == filter ? .primary : .secondary)
                        
                        // Active indicator bar
                        Capsule()
                            .fill(
                                listFilter == filter
                                ? LinearGradient(
                                    colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Templates
    
    private var displayedTemplates: [PackingList] {
        if showAllTemplates {
            return viewModel.templates
        }
        return Array(viewModel.templates.prefix(3))
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Templates")
                    .font(.title3.bold())
                
                Spacer()
                
                if viewModel.templates.count > 3 {
                    Button {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showAllTemplates.toggle()
                        }
                    } label: {
                        Text(showAllTemplates ? "Show Less" : "See All")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                ForEach(displayedTemplates) { template in
                    TemplateRow(template: template) {
                        viewModel.duplicateTemplate(template)
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed List Filters
    
    private var ongoingLists: [PackingList] {
        viewModel.customLists.filter { $0.progress < 1.0 }
    }
    
    private var pastLists: [PackingList] {
        viewModel.customLists.filter { $0.progress >= 1.0 }
    }
    
    // MARK: - Custom Lists
    
    private var customListsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if filteredLists.isEmpty && !searchText.isEmpty {
                emptySearchState
            } else if filteredLists.isEmpty {
                emptyFilterState
            } else {
                customListRows
            }
        }
    }
    
    private var customListRows: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredLists) { list in
                NavigationLink(destination: ListDetailView(list: list, viewModel: viewModel)) {
                    CustomListRow(list: list)
                        .scaleEffect(appearAnimations.contains(list.id) ? 1.0 : 0.9)
                        .opacity(appearAnimations.contains(list.id) ? 1.0 : 0)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 0.35)) {
                                _ = appearAnimations.insert(list.id)
                            }
                        }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        deleteListWithConfirmation(list)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func deleteListWithConfirmation(_ list: PackingList) {
        listToDelete = list
        showDeleteConfirmation = true
    }
    
    private var filteredLists: [PackingList] {
        let base: [PackingList]
        switch listFilter {
        case .ongoing:
            base = ongoingLists
        case .past:
            base = pastLists
        }
        
        if searchText.isEmpty { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var emptyFilterState: some View {
        VStack(spacing: 16) {
            Image(systemName: listFilter == .ongoing ? "tray" : "checkmark.seal")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(listFilter == .ongoing ? "No ongoing lists" : "No completed lists")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            
            Text(listFilter == .ongoing
                 ? "Create a new list or use a template above"
                 : "Complete a list to see it here")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            if listFilter == .ongoing {
                Button {
                    showNewListSheet = true
                } label: {
                    Label("Create List", systemImage: "plus")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "#667eea")?.opacity(0.3) ?? .blue.opacity(0.3), radius: 8, y: 4)
                        )
                }
            }
        }
        .padding(.vertical, 40)
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No results for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search lists...", text: $text)
                .font(.body)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Template Card

struct TemplateRow: View {
    let template: PackingList
    let onUse: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(template.color.gradient.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: template.icon)
                    .font(.system(size: 22))
                    .foregroundColor(template.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.body.bold())
                    .foregroundColor(.primary)
                
                Text("\(template.totalCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Use button
            Button {
                onUse()
            } label: {
                Text("Use")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(template.color.gradient)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: template.color.opacity(0.06), radius: 6, y: 3)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.2)) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Custom List Row

struct CustomListRow: View {
    let list: PackingList
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(list.color.gradient.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: list.icon)
                    .font(.system(size: 22))
                    .foregroundColor(list.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.body.bold())
                    .foregroundColor(.primary)
                
                Text("\(list.packedCount)/\(list.totalCount) packed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: CGFloat(list.progress))
                    .stroke(list.color.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(list.progress * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

