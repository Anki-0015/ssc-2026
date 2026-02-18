//
//  PrepItem.swift
//  PocketPrep
//
//  SwiftData model for individual packing items
//

import Foundation
import SwiftData

@Model
final class PrepItem {
    var id: UUID
    var name: String
    var icon: String
    var isPacked: Bool
    var mode: String
    var createdAt: Date
    
    // v2.0 Enhancements
    var notes: String?
    var category: String
    var lastPackedDate: Date?
    var timesUsed: Int
    
    // Relationship to PackingList
    var packingList: PackingList?
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        isPacked: Bool = false,
        mode: String = "",
        createdAt: Date = Date(),
        notes: String? = nil,
        category: String = "Other",
        lastPackedDate: Date? = nil,
        timesUsed: Int = 0,
        packingList: PackingList? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isPacked = isPacked
        self.mode = mode
        self.createdAt = createdAt
        self.notes = notes
        self.category = category
        self.lastPackedDate = lastPackedDate
        self.timesUsed = timesUsed
        self.packingList = packingList
    }
}
