//
//  ListDetailView.swift
//  PocketPrep
//
//  Competition-level list detail with confetti, progress, editing
//

import SwiftUI

struct ListDetailView: View {
    let list: PackingList
    @ObservedObject var viewModel: ListsViewModel
    
    @State private var showAddItem = false
    @State private var showConfetti = false
    @State private var previousProgress: Double = 0
    @State private var editingItem: PrepItem?
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Progress Header
                    progressHeader
                    
                    // Items by category
                    itemsSection
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    showAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(viewModel: viewModel, list: list)
        }
        .sheet(item: $editingItem) { item in
            EditItemSheet(viewModel: viewModel, item: item)
        }
        .onAppear {
            previousProgress = list.progress
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = list.progress
            }
        }
        .onChange(of: list.progress) { oldVal, newVal in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newVal
            }
            
            // Trigger confetti when reaching 100%
            if newVal >= 1.0 && oldVal < 1.0 {
                showConfetti = true
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    showConfetti = false
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // Glow when complete
                if animatedProgress >= 1.0 {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 16)
                        .frame(width: 120, height: 120)
                        .blur(radius: 8)
                }
                
                // Center
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    
                    Text(statusText)
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                }
            }
            
            // Packed count
            HStack(spacing: 16) {
                Label("\(list.packedCount) packed", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                
                Label("\(list.totalCount - list.packedCount) remaining", systemImage: "circle")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Items Section
    
    private var itemsSection: some View {
        let grouped = Dictionary(grouping: list.items) { $0.category }
        let sortedKeys = grouped.keys.sorted()
        
        return VStack(spacing: 16) {
            if list.items.isEmpty {
                emptyState
            } else {
                ForEach(sortedKeys, id: \.self) { category in
                    if let items = grouped[category] {
                        CategorySection(
                            category: category,
                            items: items.sorted { $0.createdAt < $1.createdAt },
                            onToggle: { item in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    viewModel.toggleItem(item)
                                }
                            },
                            onEdit: { item in
                                editingItem = item
                            },
                            onDelete: { item in
                                withAnimation {
                                    viewModel.deleteItem(item, from: list)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("No Items Yet")
                .font(.headline)
            
            Text("Tap + to start adding items")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showAddItem = true
            } label: {
                Label("Add Item", systemImage: "plus")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue.gradient))
            }
        }
        .padding(.vertical, 50)
    }
    
    private var progressGradient: LinearGradient {
        if animatedProgress >= 1.0 {
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if animatedProgress >= 0.5 {
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private var statusText: String {
        if animatedProgress >= 1.0 { return "All Done!" }
        if animatedProgress >= 0.75 { return "Almost!" }
        if animatedProgress >= 0.5 { return "Halfway" }
        if animatedProgress > 0 { return "Packing..." }
        return "Start!"
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: String
    let items: [PrepItem]
    let onToggle: (PrepItem) -> Void
    let onEdit: (PrepItem) -> Void
    let onDelete: (PrepItem) -> Void
    
    @State private var isExpanded = true
    
    var packedCount: Int { items.filter(\.isPacked).count }
    
    var categoryColor: Color {
        ItemCategory.allCases.first(where: { $0.rawValue == category })?.color ?? .gray
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeOut(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: ItemCategory.allCases.first(where: { $0.rawValue == category })?.icon ?? "tag")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(categoryColor)
                    
                    Text(category)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text("\(packedCount)/\(items.count)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(categoryColor.gradient))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            
            if isExpanded {
                Divider().padding(.horizontal, 14)
                
                ForEach(items) { item in
                    ItemRow(
                        item: item,
                        categoryColor: categoryColor,
                        onToggle: onToggle,
                        onEdit: onEdit,
                        onDelete: onDelete
                    )
                    
                    if item.id != items.last?.id {
                        Divider().padding(.leading, 60)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Item Row

struct ItemRow: View {
    let item: PrepItem
    let categoryColor: Color
    let onToggle: (PrepItem) -> Void
    let onEdit: (PrepItem) -> Void
    let onDelete: (PrepItem) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                onToggle(item)
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(item.isPacked ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
                        .background(Circle().fill(item.isPacked ? categoryColor : Color.clear))
                        .frame(width: 26, height: 26)
                    
                    if item.isPacked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 16))
                .foregroundColor(item.isPacked ? .secondary : categoryColor)
                .frame(width: 24)
            
            // Name
            Text(item.name)
                .font(.body)
                .foregroundColor(item.isPacked ? .secondary : .primary)
                .strikethrough(item.isPacked, color: .secondary)
            
            Spacer()
            
            // Edit button
            Button { onEdit(item) } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            // Delete button
            Button { onDelete(item) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            Button { onToggle(item) } label: {
                Label(item.isPacked ? "Unpack" : "Pack", systemImage: item.isPacked ? "xmark.circle" : "checkmark.circle")
            }
            Button { onEdit(item) } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) { onDelete(item) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ListsViewModel
    let list: PackingList
    
    @State private var name = ""
    @State private var icon = "checkmark.circle"
    @State private var category = "Other"
    
    let icons = [
        "checkmark.circle", "bag", "book.closed", "laptopcomputer",
        "iphone", "headphones", "waterbottle", "creditcard",
        "key", "shoe.2", "backpack", "tshirt",
        "doc.text", "drop", "fork.knife", "cross.case", "camera",
        "umbrella", "sunglasses", "cable.connector"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name", text: $name)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat.rawValue)
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(icons, id: \.self) { ic in
                            Button {
                                icon = ic
                                let gen = UISelectionFeedbackGenerator()
                                gen.selectionChanged()
                            } label: {
                                Image(systemName: ic)
                                    .font(.system(size: 22))
                                    .foregroundColor(icon == ic ? .white : .primary)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(icon == ic ? Color.accentColor : Color(.systemGray6))
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addItem(to: list, name: name, icon: icon, category: category)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }
}

// MARK: - Edit Item Sheet

struct EditItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ListsViewModel
    let item: PrepItem
    
    @State private var name: String
    @State private var icon: String
    @State private var notes: String
    @State private var category: String
    
    init(viewModel: ListsViewModel, item: PrepItem) {
        self.viewModel = viewModel
        self.item = item
        _name = State(initialValue: item.name)
        _icon = State(initialValue: item.icon)
        _notes = State(initialValue: item.notes ?? "")
        _category = State(initialValue: item.category)
    }
    
    let icons = [
        "checkmark.circle", "bag", "book.closed", "laptopcomputer",
        "iphone", "headphones", "waterbottle", "creditcard",
        "key", "shoe.2", "backpack", "tshirt",
        "doc.text", "drop", "fork.knife", "cross.case", "camera",
        "umbrella", "sunglasses", "cable.connector"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name", text: $name)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat.rawValue)
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(icons, id: \.self) { ic in
                            Button {
                                icon = ic
                            } label: {
                                Image(systemName: ic)
                                    .font(.system(size: 22))
                                    .foregroundColor(icon == ic ? .white : .primary)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(icon == ic ? Color.accentColor : Color(.systemGray6))
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateItem(item, name: name, icon: icon, notes: notes.isEmpty ? nil : notes, category: category)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }
}
