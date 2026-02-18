//
//  AIChatViewModel.swift
//  PocketPrep
//
//  AI chat logic — uses Apple Foundation Models when available
//  Falls back to local suggestions for unsupported devices
//

import Foundation
import SwiftUI
import Combine
// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

// MARK: - ViewModel

@MainActor
class AIChatViewModel: ObservableObject {
    
    @Published var messages: [ChatMessage] = []
    @Published var suggestions: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let aiService = FoundationModelService()
    
    init() {}
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        suggestions = []
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let response = try await aiService.generateSuggestions(for: text)
                
                // Parse comma-separated suggestions
                let items = response
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                let aiMessage = ChatMessage(
                    text: "Here are some items I'd suggest packing:",
                    isUser: false
                )
                messages.append(aiMessage)
                suggestions = items
                isLoading = false
                
            } catch {
                // Fallback to local suggestions
                let fallbackItems = generateLocalSuggestions(for: text)
                
                let aiMessage = ChatMessage(
                    text: "Here are some suggestions based on your query:",
                    isUser: false
                )
                messages.append(aiMessage)
                suggestions = fallbackItems
                isLoading = false
            }
        }
    }
    
    // MARK: - Remove Suggestion
    
    func removeSuggestion(_ suggestion: String) {
        withAnimation {
            suggestions.removeAll { $0 == suggestion }
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Clear Chat
    
    func clearChat() {
        messages = []
        suggestions = []
        isLoading = false
        errorMessage = nil
    }
    
    // MARK: - Icon Determination (Public for use by AIAssistantView)
    
    func determineIcon(for itemName: String) -> String {
        let lowercased = itemName.lowercased()
        
        if lowercased.contains("phone") { return "iphone" }
        if lowercased.contains("laptop") || lowercased.contains("computer") { return "laptopcomputer" }
        if lowercased.contains("charger") || lowercased.contains("cable") { return "cable.connector" }
        if lowercased.contains("headphone") || lowercased.contains("earphone") { return "headphones" }
        if lowercased.contains("bottle") || lowercased.contains("water") { return "waterbottle" }
        if lowercased.contains("book") || lowercased.contains("notebook") { return "book.closed" }
        if lowercased.contains("bag") || lowercased.contains("backpack") { return "bag" }
        if lowercased.contains("wallet") || lowercased.contains("purse") { return "creditcard" }
        if lowercased.contains("key") { return "key" }
        if lowercased.contains("umbrella") { return "umbrella" }
        if lowercased.contains("sunglasses") || lowercased.contains("glasses") { return "sunglasses" }
        if lowercased.contains("shoe") { return "shoe.2" }
        if lowercased.contains("towel") { return "tablecloth" }
        if lowercased.contains("passport") { return "doc.text" }
        if lowercased.contains("ticket") { return "ticket" }
        if lowercased.contains("camera") { return "camera" }
        if lowercased.contains("tent") { return "tent" }
        if lowercased.contains("flash") || lowercased.contains("torch") { return "flashlight.on.fill" }
        if lowercased.contains("jacket") || lowercased.contains("cloth") || lowercased.contains("shirt") { return "tshirt" }
        if lowercased.contains("sunscreen") || lowercased.contains("lotion") { return "drop" }
        if lowercased.contains("medicine") || lowercased.contains("first aid") { return "cross.case" }
        if lowercased.contains("snack") || lowercased.contains("food") { return "fork.knife" }
        
        return "checkmark.circle"
    }
    
    func determineCategory(for itemName: String) -> String {
        let lowercased = itemName.lowercased()
        
        if lowercased.contains("phone") || lowercased.contains("laptop") ||
            lowercased.contains("charger") || lowercased.contains("headphone") ||
            lowercased.contains("camera") || lowercased.contains("tablet") ||
            lowercased.contains("flashlight") {
            return "Electronics"
        }
        if lowercased.contains("shirt") || lowercased.contains("pants") ||
            lowercased.contains("shoe") || lowercased.contains("jacket") ||
            lowercased.contains("socks") || lowercased.contains("clothes") ||
            lowercased.contains("swimsuit") {
            return "Clothing"
        }
        if lowercased.contains("passport") || lowercased.contains("ticket") ||
            lowercased.contains("id") || lowercased.contains("license") {
            return "Documents"
        }
        if lowercased.contains("toothbrush") || lowercased.contains("soap") ||
            lowercased.contains("shampoo") || lowercased.contains("sunscreen") {
            return "Toiletries"
        }
        if lowercased.contains("water") || lowercased.contains("snack") ||
            lowercased.contains("food") || lowercased.contains("drink") {
            return "Food & Drinks"
        }
        if lowercased.contains("medicine") || lowercased.contains("first aid") {
            return "Health & Medicine"
        }
        if lowercased.contains("bag") || lowercased.contains("wallet") ||
            lowercased.contains("sunglasses") || lowercased.contains("umbrella") {
            return "Accessories"
        }
        
        return "Other"
    }
    
    // MARK: - Local Fallback
    
    private func generateLocalSuggestions(for query: String) -> [String] {
        let lowercased = query.lowercased()
        
        if lowercased.contains("camp") {
            return ["Tent", "Sleeping Bag", "Flashlight", "First Aid Kit", "Water Bottle", "Insect Repellent"]
        }
        if lowercased.contains("beach") || lowercased.contains("swim") {
            return ["Sunscreen", "Towel", "Swimsuit", "Sunglasses", "Water Bottle", "Sandals"]
        }
        if lowercased.contains("work") || lowercased.contains("business") || lowercased.contains("conference") {
            return ["Laptop", "Charger", "Business Cards", "Notebook", "Formal Wear", "ID Badge"]
        }
        if lowercased.contains("gym") || lowercased.contains("workout") {
            return ["Workout Clothes", "Sneakers", "Water Bottle", "Towel", "Headphones", "Deodorant"]
        }
        if lowercased.contains("college") || lowercased.contains("school") || lowercased.contains("class") {
            return ["Laptop", "Notebook", "Pen", "Charger", "Water Bottle", "ID Card"]
        }
        if lowercased.contains("travel") || lowercased.contains("trip") || lowercased.contains("vacation") {
            return ["Passport", "Phone Charger", "Clothes", "Toiletries", "Camera", "Snacks"]
        }
        
        // Generic
        return ["Phone Charger", "Water Bottle", "Wallet", "Keys", "Headphones", "Snacks"]
    }
}
