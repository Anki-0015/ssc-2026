//
//  ListsView.swift
//  PocketPrep
//
//  Competition-level lists management
//  Templates, custom lists, staggered animations
//

import SwiftUI

struct ListsView: View {
    @ObservedObject var viewModel: ListsViewModel
    @State private var showNewListSheet = false
    @State private var appearAnimations: Set<UUID> = []
    @State private var searchText = ""
    @State private var showAllTemplates = false
    
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
        }
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
    
    // MARK: - Custom Lists
    
    private var customListsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !viewModel.customLists.isEmpty {
                HStack {
                    Text("My Lists")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Text("\(viewModel.customLists.count)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue.gradient))
                }
                .padding(.horizontal, 20)
            }
            
            if filteredLists.isEmpty && !searchText.isEmpty {
                emptySearchState
            } else if filteredLists.isEmpty {
                emptyState
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
                        withAnimation { viewModel.deleteList(list) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var filteredLists: [PackingList] {
        if searchText.isEmpty { return viewModel.customLists }
        return viewModel.customLists.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("No Lists Yet")
                .font(.title3.bold())
            
            Text("Create your first list or use a template above!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showNewListSheet = true
            } label: {
                Label("Create List", systemImage: "plus")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue.gradient))
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

