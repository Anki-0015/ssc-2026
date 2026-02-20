//
//  AIChatViewModel.swift
//  PocketPrep
//
//  AI chat logic — multi-turn, streaming, categorized suggestions
//  Uses Apple Foundation Models when available, rich local fallback otherwise
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
    @Published var categorizedSuggestions: [SuggestionCategory] = []
    @Published var isLoading: Bool = false
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""
    @Published var errorMessage: String?
    @Published var tripContext: TripContext?
    
    // Legacy flat access (for add-to-list)
    var suggestions: [String] {
        categorizedSuggestions.flatMap { $0.items }
    }
    
    private let aiService = FoundationModelService()
    
    init() {}
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        categorizedSuggestions = []
        errorMessage = nil
        isLoading = true
        isStreaming = false
        streamingText = ""
        
        Task {
            do {
                // Try streaming first for real-time feel
                var finalText = ""
                isStreaming = true
                
                try await aiService.streamResponse(for: text, context: tripContext) { [weak self] partial in
                    Task { @MainActor in
                        self?.streamingText = partial
                    }
                }
                
                finalText = streamingText
                isStreaming = false
                
                // Parse into categories
                let categories = FoundationModelService.parseCategorizedResponse(finalText)
                
                let aiMessage = ChatMessage(
                    text: categories.isEmpty
                        ? finalText
                        : "Here's what I'd suggest packing:",
                    isUser: false
                )
                messages.append(aiMessage)
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    categorizedSuggestions = categories
                }
                
                streamingText = ""
                isLoading = false
                
            } catch {
                isStreaming = false
                streamingText = ""
                
                // Rich local fallback
                let fallbackCategories = generateLocalFallback(for: text)
                
                let aiMessage = ChatMessage(
                    text: "Here are some suggestions I'd recommend:",
                    isUser: false
                )
                messages.append(aiMessage)
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    categorizedSuggestions = fallbackCategories
                }
                isLoading = false
            }
        }
    }
    
    // MARK: - Send with Context
    
    func sendWithContext(type: TripContext.TripType, duration: TripContext.TripDuration, climate: TripContext.TripClimate) {
        let ctx = TripContext(type: type, duration: duration, climate: climate)
        self.tripContext = ctx
        let prompt = "I'm going on \(ctx.promptDescription). What should I pack?"
        sendMessage(prompt)
    }
    
    // MARK: - Remove Suggestion
    
    func removeSuggestion(_ suggestion: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            for i in categorizedSuggestions.indices {
                let filtered = categorizedSuggestions[i].items.filter { $0 != suggestion }
                if filtered.count != categorizedSuggestions[i].items.count {
                    categorizedSuggestions[i] = SuggestionCategory(
                        name: categorizedSuggestions[i].name,
                        items: filtered
                    )
                }
            }
            // Remove empty categories
            categorizedSuggestions.removeAll { $0.items.isEmpty }
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Clear Chat
    
    func clearChat() {
        messages = []
        categorizedSuggestions = []
        isLoading = false
        isStreaming = false
        streamingText = ""
        errorMessage = nil
        tripContext = nil
        aiService.resetSession()
    }
    
    // MARK: - Icon Determination
    
    func determineIcon(for itemName: String) -> String {
        let lowercased = itemName.lowercased()
        
        // Electronics
        if lowercased.contains("phone") { return "iphone" }
        if lowercased.contains("laptop") || lowercased.contains("computer") { return "laptopcomputer" }
        if lowercased.contains("charger") || lowercased.contains("cable") { return "cable.connector" }
        if lowercased.contains("headphone") || lowercased.contains("earphone") || lowercased.contains("airpod") || lowercased.contains("earbud") { return "headphones" }
        if lowercased.contains("battery") || lowercased.contains("power bank") { return "battery.100" }
        if lowercased.contains("camera") { return "camera" }
        if lowercased.contains("tablet") || lowercased.contains("ipad") { return "ipad" }
        if lowercased.contains("watch") { return "applewatch" }
        if lowercased.contains("speaker") { return "hifispeaker" }
        if lowercased.contains("adapter") || lowercased.contains("converter") { return "powerplug" }
        
        // Clothing
        if lowercased.contains("jacket") || lowercased.contains("coat") || lowercased.contains("hoodie") { return "tshirt" }
        if lowercased.contains("shirt") || lowercased.contains("tee") || lowercased.contains("top") { return "tshirt" }
        if lowercased.contains("pants") || lowercased.contains("jeans") || lowercased.contains("shorts") { return "figure.walk" }
        if lowercased.contains("socks") || lowercased.contains("underwear") { return "hanger" }
        if lowercased.contains("swimsuit") || lowercased.contains("bikini") || lowercased.contains("trunks") { return "figure.pool.swim" }
        if lowercased.contains("hat") || lowercased.contains("cap") || lowercased.contains("beanie") { return "crown" }
        if lowercased.contains("sweater") || lowercased.contains("fleece") || lowercased.contains("thermal") { return "tshirt" }
        if lowercased.contains("dress") || lowercased.contains("formal") || lowercased.contains("suit") { return "hanger" }
        if lowercased.contains("glove") || lowercased.contains("mitten") { return "hand.raised" }
        if lowercased.contains("scarf") { return "wind" }
        if lowercased.contains("raincoat") || lowercased.contains("poncho") { return "cloud.rain" }
        
        // Footwear
        if lowercased.contains("shoe") || lowercased.contains("sneaker") || lowercased.contains("boot") { return "shoe.2" }
        if lowercased.contains("sandal") || lowercased.contains("flip flop") { return "shoe.2" }
        if lowercased.contains("slipper") { return "shoe.2" }
        
        // Documents
        if lowercased.contains("passport") { return "doc.text" }
        if lowercased.contains("ticket") || lowercased.contains("boarding") { return "ticket" }
        if lowercased.contains("id") || lowercased.contains("license") || lowercased.contains("card") { return "creditcard" }
        if lowercased.contains("insurance") || lowercased.contains("document") { return "doc.text.fill" }
        if lowercased.contains("map") || lowercased.contains("guidebook") { return "map" }
        
        // Toiletries
        if lowercased.contains("toothbrush") || lowercased.contains("toothpaste") { return "mouth" }
        if lowercased.contains("shampoo") || lowercased.contains("conditioner") || lowercased.contains("soap") { return "drop" }
        if lowercased.contains("sunscreen") || lowercased.contains("spf") || lowercased.contains("lotion") { return "sun.max" }
        if lowercased.contains("deodorant") || lowercased.contains("perfume") || lowercased.contains("cologne") { return "aqi.medium" }
        if lowercased.contains("razor") || lowercased.contains("shaving") { return "scissors" }
        if lowercased.contains("towel") { return "tablecloth" }
        if lowercased.contains("tissue") || lowercased.contains("wipes") { return "square.stack" }
        if lowercased.contains("lip balm") || lowercased.contains("chapstick") { return "mouth" }
        
        // Accessories
        if lowercased.contains("bottle") || lowercased.contains("water") { return "waterbottle" }
        if lowercased.contains("book") || lowercased.contains("notebook") || lowercased.contains("journal") { return "book.closed" }
        if lowercased.contains("pen") || lowercased.contains("pencil") { return "pencil" }
        if lowercased.contains("bag") || lowercased.contains("backpack") || lowercased.contains("daypack") { return "bag" }
        if lowercased.contains("wallet") || lowercased.contains("purse") || lowercased.contains("money") || lowercased.contains("cash") { return "creditcard" }
        if lowercased.contains("key") { return "key" }
        if lowercased.contains("umbrella") { return "umbrella" }
        if lowercased.contains("sunglasses") || lowercased.contains("glasses") { return "sunglasses" }
        if lowercased.contains("belt") { return "circle" }
        if lowercased.contains("jewelry") || lowercased.contains("necklace") || lowercased.contains("ring") { return "sparkle" }
        if lowercased.contains("pillow") || lowercased.contains("eye mask") { return "moon.zzz" }
        
        // Outdoor / Camping
        if lowercased.contains("tent") { return "tent" }
        if lowercased.contains("sleeping bag") || lowercased.contains("sleeping pad") { return "bed.double" }
        if lowercased.contains("flash") || lowercased.contains("torch") { return "flashlight.on.fill" }
        if lowercased.contains("compass") { return "safari" }
        if lowercased.contains("binocular") { return "binoculars" }
        if lowercased.contains("knife") || lowercased.contains("multi-tool") { return "wrench.and.screwdriver" }
        if lowercased.contains("rope") || lowercased.contains("cord") { return "link" }
        if lowercased.contains("stove") || lowercased.contains("cooker") { return "flame" }
        if lowercased.contains("cooler") || lowercased.contains("ice") { return "snowflake" }
        if lowercased.contains("hammock") { return "tree" }
        
        // Health
        if lowercased.contains("medicine") || lowercased.contains("medication") || lowercased.contains("pill") { return "pills" }
        if lowercased.contains("first aid") || lowercased.contains("bandage") { return "cross.case" }
        if lowercased.contains("insect") || lowercased.contains("bug spray") || lowercased.contains("repellent") { return "ladybug" }
        if lowercased.contains("mask") || lowercased.contains("sanitizer") { return "hands.sparkles" }
        if lowercased.contains("vitamin") || lowercased.contains("supplement") { return "pill" }
        
        // Food
        if lowercased.contains("snack") || lowercased.contains("food") || lowercased.contains("meal") { return "fork.knife" }
        if lowercased.contains("coffee") || lowercased.contains("tea") { return "cup.and.saucer" }
        if lowercased.contains("protein") || lowercased.contains("energy bar") { return "bolt" }
        
        return "checkmark.circle"
    }
    
    func determineCategory(for itemName: String) -> String {
        let lowercased = itemName.lowercased()
        
        if lowercased.contains("phone") || lowercased.contains("laptop") ||
            lowercased.contains("charger") || lowercased.contains("headphone") ||
            lowercased.contains("camera") || lowercased.contains("tablet") ||
            lowercased.contains("flashlight") || lowercased.contains("battery") ||
            lowercased.contains("power bank") || lowercased.contains("adapter") ||
            lowercased.contains("speaker") || lowercased.contains("watch") ||
            lowercased.contains("airpod") || lowercased.contains("earbud") {
            return "Electronics"
        }
        if lowercased.contains("shirt") || lowercased.contains("pants") ||
            lowercased.contains("shoe") || lowercased.contains("jacket") ||
            lowercased.contains("socks") || lowercased.contains("clothes") ||
            lowercased.contains("swimsuit") || lowercased.contains("dress") ||
            lowercased.contains("coat") || lowercased.contains("sweater") ||
            lowercased.contains("jeans") || lowercased.contains("shorts") ||
            lowercased.contains("boot") || lowercased.contains("sandal") ||
            lowercased.contains("hat") || lowercased.contains("cap") ||
            lowercased.contains("hoodie") || lowercased.contains("glove") ||
            lowercased.contains("scarf") || lowercased.contains("beanie") ||
            lowercased.contains("thermal") || lowercased.contains("bikini") ||
            lowercased.contains("trunks") || lowercased.contains("sneaker") ||
            lowercased.contains("raincoat") || lowercased.contains("poncho") ||
            lowercased.contains("fleece") || lowercased.contains("formal") ||
            lowercased.contains("suit") || lowercased.contains("underwear") {
            return "Clothing"
        }
        if lowercased.contains("passport") || lowercased.contains("ticket") ||
            lowercased.contains("id") || lowercased.contains("license") ||
            lowercased.contains("insurance") || lowercased.contains("boarding") ||
            lowercased.contains("document") || lowercased.contains("card") {
            return "Documents"
        }
        if lowercased.contains("toothbrush") || lowercased.contains("soap") ||
            lowercased.contains("shampoo") || lowercased.contains("sunscreen") ||
            lowercased.contains("deodorant") || lowercased.contains("razor") ||
            lowercased.contains("towel") || lowercased.contains("lotion") ||
            lowercased.contains("toothpaste") || lowercased.contains("conditioner") ||
            lowercased.contains("perfume") || lowercased.contains("cologne") ||
            lowercased.contains("wipes") || lowercased.contains("tissue") ||
            lowercased.contains("lip balm") || lowercased.contains("chapstick") {
            return "Toiletries"
        }
        if lowercased.contains("water") || lowercased.contains("snack") ||
            lowercased.contains("food") || lowercased.contains("drink") ||
            lowercased.contains("coffee") || lowercased.contains("tea") ||
            lowercased.contains("protein") || lowercased.contains("energy bar") {
            return "Food & Drinks"
        }
        if lowercased.contains("medicine") || lowercased.contains("first aid") ||
            lowercased.contains("insect") || lowercased.contains("repellent") ||
            lowercased.contains("sanitizer") || lowercased.contains("mask") ||
            lowercased.contains("vitamin") || lowercased.contains("pill") ||
            lowercased.contains("bandage") || lowercased.contains("medication") {
            return "Health & Medicine"
        }
        if lowercased.contains("bag") || lowercased.contains("wallet") ||
            lowercased.contains("sunglasses") || lowercased.contains("umbrella") ||
            lowercased.contains("belt") || lowercased.contains("jewelry") ||
            lowercased.contains("glasses") || lowercased.contains("key") ||
            lowercased.contains("pillow") || lowercased.contains("eye mask") {
            return "Accessories"
        }
        if lowercased.contains("tent") || lowercased.contains("sleeping bag") ||
            lowercased.contains("compass") || lowercased.contains("binocular") ||
            lowercased.contains("knife") || lowercased.contains("rope") ||
            lowercased.contains("hammock") || lowercased.contains("stove") ||
            lowercased.contains("cooler") || lowercased.contains("multi-tool") {
            return "Outdoor Gear"
        }
        if lowercased.contains("book") || lowercased.contains("notebook") ||
            lowercased.contains("pen") || lowercased.contains("journal") ||
            lowercased.contains("game") || lowercased.contains("puzzle") {
            return "Entertainment"
        }
        
        return "Other"
    }
    
    // MARK: - Rich Local Fallback
    
    private func generateLocalFallback(for query: String) -> [SuggestionCategory] {
        let lowercased = query.lowercased()
        
        if lowercased.contains("camp") || lowercased.contains("outdoor") {
            return [
                SuggestionCategory(name: "Outdoor Gear", items: ["Tent", "Sleeping Bag", "Sleeping Pad", "Flashlight", "Multi-Tool", "Compass", "Rope", "Camp Stove"]),
                SuggestionCategory(name: "Clothing", items: ["Hiking Boots", "Warm Jacket", "Quick-Dry Pants", "Wool Socks (3)", "Rain Poncho", "Beanie"]),
                SuggestionCategory(name: "Health & Safety", items: ["First Aid Kit", "Insect Repellent", "SPF 50 Sunscreen", "Water Purification Tablets"]),
                SuggestionCategory(name: "Food & Snacks", items: ["Trail Mix", "Energy Bars", "Reusable Water Bottle", "Instant Coffee"]),
                SuggestionCategory(name: "Electronics", items: ["Portable Battery", "Headlamp", "Phone Charger"])
            ]
        }
        
        if lowercased.contains("beach") || lowercased.contains("swim") || lowercased.contains("tropical") {
            return [
                SuggestionCategory(name: "Clothing", items: ["Swimsuit (2)", "Cover-Up", "Shorts (3)", "Tank Tops (3)", "Flip Flops", "Sun Hat"]),
                SuggestionCategory(name: "Toiletries & Hygiene", items: ["SPF 50 Sunscreen", "After-Sun Lotion", "Lip Balm with SPF", "Waterproof Hair Ties"]),
                SuggestionCategory(name: "Accessories", items: ["Beach Towel", "Sunglasses", "Waterproof Phone Pouch", "Beach Bag", "Reusable Water Bottle"]),
                SuggestionCategory(name: "Electronics", items: ["Waterproof Speaker", "Portable Charger", "Camera"]),
                SuggestionCategory(name: "Health & Safety", items: ["Insect Repellent", "Aloe Vera Gel", "Reef-Safe Sunscreen"])
            ]
        }
        
        if lowercased.contains("work") || lowercased.contains("business") || lowercased.contains("conference") || lowercased.contains("meeting") {
            return [
                SuggestionCategory(name: "Electronics", items: ["Laptop", "Phone Charger", "Portable Battery", "Presentation Adapter", "Wireless Mouse"]),
                SuggestionCategory(name: "Documents", items: ["Business Cards", "ID Badge", "Agenda / Notes", "Boarding Pass"]),
                SuggestionCategory(name: "Clothing", items: ["Formal Shirt (2)", "Dress Pants", "Blazer", "Dress Shoes", "Belt", "Tie / Scarf"]),
                SuggestionCategory(name: "Accessories", items: ["Notebook", "Quality Pen", "Laptop Bag", "Watch", "Breath Mints"]),
                SuggestionCategory(name: "Toiletries & Hygiene", items: ["Deodorant", "Cologne / Perfume", "Toothbrush", "Hair Styling Product"])
            ]
        }
        
        if lowercased.contains("gym") || lowercased.contains("workout") || lowercased.contains("fitness") || lowercased.contains("exercise") {
            return [
                SuggestionCategory(name: "Clothing", items: ["Workout Shorts", "Compression Shirt", "Running Shoes", "Athletic Socks", "Sports Bra", "Gym Gloves"]),
                SuggestionCategory(name: "Accessories", items: ["Gym Bag", "Reusable Water Bottle", "Resistance Bands", "Jump Rope", "Foam Roller"]),
                SuggestionCategory(name: "Electronics", items: ["Wireless Earbuds", "Fitness Tracker", "Phone Armband"]),
                SuggestionCategory(name: "Toiletries & Hygiene", items: ["Deodorant", "Quick-Dry Towel", "Body Wash", "Dry Shampoo"]),
                SuggestionCategory(name: "Food & Snacks", items: ["Protein Shake", "Energy Bar", "Banana", "Electrolyte Drink"])
            ]
        }
        
        if lowercased.contains("college") || lowercased.contains("school") || lowercased.contains("class") || lowercased.contains("university") {
            return [
                SuggestionCategory(name: "Electronics", items: ["Laptop", "Charger", "Portable Battery", "USB Drive", "Wireless Earbuds"]),
                SuggestionCategory(name: "Accessories", items: ["Backpack", "Notebook (2)", "Pens & Highlighters", "Planner", "Water Bottle", "Pencil Case"]),
                SuggestionCategory(name: "Documents", items: ["Student ID", "Class Schedule", "Library Card"]),
                SuggestionCategory(name: "Food & Snacks", items: ["Reusable Coffee Mug", "Healthy Snacks", "Lunch Box"]),
                SuggestionCategory(name: "Clothing", items: ["Comfortable Sneakers", "Light Jacket", "Extra Layer"])
            ]
        }

        if lowercased.contains("hik") || lowercased.contains("trek") || lowercased.contains("mountain") {
            return [
                SuggestionCategory(name: "Outdoor Gear", items: ["Trekking Poles", "Daypack (30L)", "Trail Map", "Compass", "Water Bladder"]),
                SuggestionCategory(name: "Clothing", items: ["Hiking Boots", "Moisture-Wicking Base Layer", "Quick-Dry Shorts", "Rain Jacket", "Wool Socks (3)", "Sun Hat"]),
                SuggestionCategory(name: "Health & Safety", items: ["First Aid Kit", "Emergency Whistle", "SPF 50 Sunscreen", "Blister Bandages", "Insect Repellent"]),
                SuggestionCategory(name: "Food & Snacks", items: ["Trail Mix", "Energy Gels", "Dried Fruit", "Reusable Water Bottle (2L)", "Electrolyte Powder"]),
                SuggestionCategory(name: "Electronics", items: ["Headlamp", "Portable Charger", "GPS Watch"])
            ]
        }
        
        if lowercased.contains("road trip") || lowercased.contains("drive") || lowercased.contains("car trip") {
            return [
                SuggestionCategory(name: "Electronics", items: ["Phone Mount", "Car Charger", "AUX Cable / Bluetooth Adapter", "Portable Battery", "Dash Cam"]),
                SuggestionCategory(name: "Food & Snacks", items: ["Cooler Bag", "Reusable Water Bottles", "Road Trip Snacks", "Coffee Thermos"]),
                SuggestionCategory(name: "Accessories", items: ["Sunglasses", "Blanket", "Pillow", "Trash Bags", "Wet Wipes"]),
                SuggestionCategory(name: "Documents", items: ["Driver's License", "Car Registration", "Insurance Card", "Roadside Assistance Card"]),
                SuggestionCategory(name: "Health & Safety", items: ["First Aid Kit", "Hand Sanitizer", "Medications", "Emergency Kit"]),
                SuggestionCategory(name: "Entertainment", items: ["Playlist / Podcasts", "Travel Games", "Book / Audiobook"])
            ]
        }
        
        if lowercased.contains("festival") || lowercased.contains("concert") || lowercased.contains("music") {
            return [
                SuggestionCategory(name: "Accessories", items: ["Fanny Pack", "Sunglasses", "Ear Plugs", "Bandana", "Reusable Water Bottle", "Clear Bag"]),
                SuggestionCategory(name: "Clothing", items: ["Comfortable Sneakers", "Layered Outfits (2-3)", "Rain Poncho", "Hat / Cap"]),
                SuggestionCategory(name: "Toiletries & Hygiene", items: ["SPF 50 Sunscreen", "Wet Wipes", "Deodorant", "Hand Sanitizer", "Lip Balm"]),
                SuggestionCategory(name: "Electronics", items: ["Portable Charger (large)", "Phone Charger Cable", "Wireless Earbuds"]),
                SuggestionCategory(name: "Health & Safety", items: ["Medications", "Electrolyte Packets", "Blister Bandages"])
            ]
        }
        
        if lowercased.contains("winter") || lowercased.contains("ski") || lowercased.contains("snow") || lowercased.contains("cold") {
            return [
                SuggestionCategory(name: "Clothing", items: ["Thermal Base Layer (2)", "Insulated Jacket", "Waterproof Pants", "Warm Beanie", "Ski Goggles", "Thick Gloves", "Wool Socks (4)", "Neck Gaiter"]),
                SuggestionCategory(name: "Outdoor Gear", items: ["Ski Pass / Lift Ticket", "Hand Warmers", "Lip Balm with SPF", "Boot Dryer"]),
                SuggestionCategory(name: "Toiletries & Hygiene", items: ["Moisturizer", "Sunscreen (yes, for snow!)", "Lip Balm", "Body Lotion"]),
                SuggestionCategory(name: "Electronics", items: ["Action Camera", "Portable Charger", "Headphones"]),
                SuggestionCategory(name: "Health & Safety", items: ["Pain Relievers", "Hot Cocoa Mix", "First Aid Kit"])
            ]
        }
        
        if lowercased.contains("travel") || lowercased.contains("trip") || lowercased.contains("vacation") || lowercased.contains("holiday") || lowercased.contains("flight") {
            return [
                SuggestionCategory(name: "Documents", items: ["Passport", "Boarding Pass", "Travel Insurance", "Hotel Confirmation", "Visa (if needed)"]),
                SuggestionCategory(name: "Electronics", items: ["Phone Charger", "Portable Battery", "Universal Adapter", "Noise-Canceling Headphones", "Kindle / E-Reader"]),
                SuggestionCategory(name: "Clothing", items: ["Versatile Outfits (5)", "Comfortable Walking Shoes", "Light Jacket", "Sleepwear", "Extra Underwear & Socks"]),
                SuggestionCategory(name: "Toiletries & Hygiene", items: ["TSA-Approved Toiletry Bag", "Toothbrush & Toothpaste", "Deodorant", "Shampoo & Conditioner", "Razor"]),
                SuggestionCategory(name: "Accessories", items: ["Neck Pillow", "Eye Mask", "Luggage Lock", "Packing Cubes", "Reusable Water Bottle"]),
                SuggestionCategory(name: "Health & Safety", items: ["Medications", "Hand Sanitizer", "Pain Relievers", "Motion Sickness Tablets"])
            ]
        }
        
        // Generic fallback
        return [
            SuggestionCategory(name: "Electronics", items: ["Phone Charger", "Portable Battery", "Headphones"]),
            SuggestionCategory(name: "Clothing", items: ["Extra T-Shirt", "Comfortable Shoes", "Light Jacket"]),
            SuggestionCategory(name: "Accessories", items: ["Wallet", "Keys", "Reusable Water Bottle", "Sunglasses"]),
            SuggestionCategory(name: "Toiletries & Hygiene", items: ["Deodorant", "Toothbrush", "Hand Sanitizer"]),
            SuggestionCategory(name: "Food & Snacks", items: ["Snack Bar", "Chewing Gum", "Mints"])
        ]
    }
}
