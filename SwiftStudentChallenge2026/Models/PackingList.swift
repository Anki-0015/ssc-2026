//
//  PackingList.swift
//  PocketPrep
//
//  SwiftData model for packing lists
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class PackingList {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var isTemplate: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \PrepItem.packingList)
    var items: [PrepItem] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "bag",
        colorHex: String = "#007AFF",
        isTemplate: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isTemplate = isTemplate
        self.createdAt = createdAt
    }
    
    // Computed properties
    var packedCount: Int {
        items.filter { $0.isPacked }.count
    }
    
    var totalCount: Int {
        items.count
    }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(packedCount) / Double(totalCount)
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
