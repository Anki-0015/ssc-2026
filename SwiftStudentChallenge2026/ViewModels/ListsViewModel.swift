//
//  ListsViewModel.swift
//  PocketPrep
//
//  Manages all packing list data and operations
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ListsViewModel: ObservableObject {
    
    @Published var lists: [PackingList] = []
    @Published var searchText: String = ""
    
    private var modelContext: ModelContext?
    
    init() {}
    
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        self.modelContext = context
        loadLists()
        seedTemplatesIfNeeded()
    }
    
    // MARK: - Data Loading
    
    func loadLists() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<PackingList>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            lists = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading lists: \(error)")
            lists = []
        }
    }
    
    // MARK: - Template Seeding
    
    private func seedTemplatesIfNeeded() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<PackingList>(
            predicate: #Predicate { $0.isTemplate == true }
        )
        
        do {
            let existing = try modelContext.fetch(descriptor)
            if !existing.isEmpty { return }
        } catch { return }
        
        for template in SampleData.templates {
            let list = PackingList(
                name: template.name,
                icon: template.icon,
                colorHex: template.color,
                isTemplate: true
            )
            
            modelContext.insert(list)
            
            for (name, icon, category) in template.items {
                let item = PrepItem(
                    name: name,
                    icon: icon,
                    category: category,
                    packingList: list
                )
                modelContext.insert(item)
            }
        }
        
        try? modelContext.save()
        loadLists()
    }
    
    // MARK: - CRUD
    
    func createList(name: String, icon: String, colorHex: String) {
        guard let modelContext = modelContext else { return }
        
        let list = PackingList(
            name: name,
            icon: icon,
            colorHex: colorHex,
            isTemplate: false
        )
        
        modelContext.insert(list)
        try? modelContext.save()
        loadLists()
        
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }
    
    /// Creates a new list and populates it with the given items in one step.
    func createListWithItems(name: String, icon: String, colorHex: String, items: [(name: String, icon: String, category: String)]) {
        guard let modelContext = modelContext else { return }
        
        let list = PackingList(
            name: name,
            icon: icon,
            colorHex: colorHex,
            isTemplate: false
        )
        
        modelContext.insert(list)
        
        for item in items {
            let prepItem = PrepItem(
                name: item.name,
                icon: item.icon,
                category: item.category,
                packingList: list
            )
            modelContext.insert(prepItem)
        }
        
        try? modelContext.save()
        loadLists()
        
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }
    
    func duplicateTemplate(_ template: PackingList) {
        guard let modelContext = modelContext else { return }
        
        let copy = PackingList(
            name: "\(template.name) Copy",
            icon: template.icon,
            colorHex: template.colorHex,
            isTemplate: false
        )
        
        modelContext.insert(copy)
        
        for item in template.items {
            let newItem = PrepItem(
                name: item.name,
                icon: item.icon,
                category: item.category,
                packingList: copy
            )
            modelContext.insert(newItem)
        }
        
        try? modelContext.save()
        loadLists()
    }
    
    func deleteList(_ list: PackingList) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(list)
        try? modelContext.save()
        loadLists()
    }
    
    // MARK: - Item Management
    
    func addItem(to list: PackingList, name: String, icon: String, category: String) {
        guard let modelContext = modelContext else { return }
        
        let item = PrepItem(
            name: name,
            icon: icon,
            category: category,
            packingList: list
        )
        
        modelContext.insert(item)
        try? modelContext.save()
        objectWillChange.send()
    }
    
    func toggleItem(_ item: PrepItem) {
        guard let modelContext = modelContext else { return }
        
        item.isPacked.toggle()
        try? modelContext.save()
        
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        
        objectWillChange.send()
    }
    
    func deleteItem(_ item: PrepItem, from list: PackingList? = nil) {
        guard let modelContext = modelContext else { return }
        modelContext.delete(item)
        try? modelContext.save()
        objectWillChange.send()
    }
    
    func updateItem(_ item: PrepItem, name: String, icon: String, notes: String?, category: String) {
        guard let modelContext = modelContext else { return }
        
        item.name = name
        item.icon = icon
        item.notes = notes
        item.category = category
        
        try? modelContext.save()
        objectWillChange.send()
    }
    
    func resetList(_ list: PackingList) {
        guard let modelContext = modelContext else { return }
        for item in list.items {
            item.isPacked = false
        }
        try? modelContext.save()
        objectWillChange.send()
    }
    
    // MARK: - Computed Properties
    
    var templates: [PackingList] {
        lists.filter { $0.isTemplate }
    }
    
    var customLists: [PackingList] {
        lists.filter { !$0.isTemplate }
    }
    
    var filteredLists: [PackingList] {
        guard !searchText.isEmpty else { return lists }
        return lists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Stats
    var totalItems: Int {
        customLists.flatMap(\.items).count
    }
    
    var totalPackedItems: Int {
        customLists.flatMap(\.items).filter(\.isPacked).count
    }
    
    var totalUnpackedItems: Int {
        totalItems - totalPackedItems
    }
    
    var overallCompletionPercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int(Double(totalPackedItems) / Double(totalItems) * 100)
    }
}
