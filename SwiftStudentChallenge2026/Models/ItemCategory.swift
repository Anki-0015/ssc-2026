//
//  ItemCategory.swift
//  PocketPrep
//
//  Category definitions for organizing packing items
//

import SwiftUI

enum ItemCategory: String, CaseIterable, Identifiable {
    case electronics = "Electronics"
    case clothing = "Clothing"
    case documents = "Documents"
    case toiletries = "Toiletries"
    case food = "Food & Drinks"
    case health = "Health & Medicine"
    case entertainment = "Entertainment"
    case accessories = "Accessories"
    case other = "Other"
    
    var id: String { rawValue }
    
    // Category icon
    var icon: String {
        switch self {
        case .electronics: return "iphone"
        case .clothing: return "tshirt"
        case .documents: return "doc.text"
        case .toiletries: return "drop"
        case .food: return "fork.knife"
        case .health: return "cross.case"
        case .entertainment: return "gamecontroller"
        case .accessories: return "bag"
        case .other: return "star"
        }
    }
    
    // Category color
    var color: Color {
        switch self {
        case .electronics: return .blue
        case .clothing: return .purple
        case .documents: return .orange
        case .toiletries: return .cyan
        case .food: return .green
        case .health: return .red
        case .entertainment: return .pink
        case .accessories: return .indigo
        case .other: return .gray
        }
    }
}
