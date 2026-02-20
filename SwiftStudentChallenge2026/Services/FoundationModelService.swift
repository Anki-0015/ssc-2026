//
//  FoundationModelService.swift
//  PocketPrep
//
//  Apple Foundation Models integration
//  Multi-turn sessions, structured output, streaming, context-aware prompting
//  Available on iPhone 16+ with Apple Intelligence
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Trip Context

struct TripContext {
    var type: TripType
    var duration: TripDuration
    var climate: TripClimate
    
    enum TripType: String, CaseIterable {
        case beach = "Beach Vacation"
        case camping = "Camping Trip"
        case business = "Business Trip"
        case travel = "Travel / Sightseeing"
        case college = "College / School"
        case gym = "Gym / Workout"
        case roadTrip = "Road Trip"
        case hiking = "Hiking / Trekking"
        case festival = "Festival / Concert"
        case winter = "Winter Sports"
        
        var emoji: String {
            switch self {
            case .beach: return "🏖️"
            case .camping: return "⛺"
            case .business: return "💼"
            case .travel: return "✈️"
            case .college: return "🎓"
            case .gym: return "💪"
            case .roadTrip: return "🚗"
            case .hiking: return "🥾"
            case .festival: return "🎵"
            case .winter: return "⛷️"
            }
        }
    }
    
    enum TripDuration: String, CaseIterable {
        case dayTrip = "Day Trip"
        case weekend = "Weekend (2-3 days)"
        case week = "1 Week"
        case extended = "2+ Weeks"
        
        var emoji: String {
            switch self {
            case .dayTrip: return "☀️"
            case .weekend: return "📅"
            case .week: return "🗓️"
            case .extended: return "🌍"
            }
        }
    }
    
    enum TripClimate: String, CaseIterable {
        case hot = "Hot & Sunny"
        case warm = "Warm & Mild"
        case cold = "Cold & Snowy"
        case rainy = "Rainy"
        case mixed = "Mixed / Unpredictable"
        
        var emoji: String {
            switch self {
            case .hot: return "☀️"
            case .warm: return "🌤️"
            case .cold: return "❄️"
            case .rainy: return "🌧️"
            case .mixed: return "🌦️"
            }
        }
    }
    
    var promptDescription: String {
        "A \(duration.rawValue.lowercased()) \(type.rawValue.lowercased()) in \(climate.rawValue.lowercased()) weather"
    }
}

// MARK: - Suggestion Category (Structured Output)

struct SuggestionCategory: Identifiable {
    let id = UUID()
    let name: String
    let items: [String]
    
    var icon: String {
        switch name.lowercased() {
        case let n where n.contains("electronic") || n.contains("tech"):
            return "iphone"
        case let n where n.contains("cloth") || n.contains("wear") || n.contains("apparel"):
            return "tshirt"
        case let n where n.contains("document") || n.contains("travel doc"):
            return "doc.text"
        case let n where n.contains("toiletr") || n.contains("hygiene") || n.contains("personal care"):
            return "drop"
        case let n where n.contains("food") || n.contains("snack") || n.contains("drink"):
            return "fork.knife"
        case let n where n.contains("health") || n.contains("medic") || n.contains("first aid") || n.contains("safety"):
            return "cross.case"
        case let n where n.contains("entertain") || n.contains("fun"):
            return "gamecontroller"
        case let n where n.contains("accessor") || n.contains("gear") || n.contains("misc"):
            return "bag"
        case let n where n.contains("outdoor") || n.contains("camping") || n.contains("adventure"):
            return "tent"
        case let n where n.contains("protection") || n.contains("weather"):
            return "umbrella"
        case let n where n.contains("comfort") || n.contains("sleep"):
            return "bed.double"
        case let n where n.contains("footwear") || n.contains("shoe"):
            return "shoe.2"
        default:
            return "star"
        }
    }
    
    var color: String {
        switch name.lowercased() {
        case let n where n.contains("electronic") || n.contains("tech"):
            return "#4facfe"
        case let n where n.contains("cloth") || n.contains("wear"):
            return "#764ba2"
        case let n where n.contains("document"):
            return "#f093fb"
        case let n where n.contains("toiletr") || n.contains("hygiene"):
            return "#43e97b"
        case let n where n.contains("food") || n.contains("snack"):
            return "#38f9d7"
        case let n where n.contains("health") || n.contains("medic") || n.contains("safety"):
            return "#f5576c"
        case let n where n.contains("outdoor") || n.contains("camping"):
            return "#fa709a"
        case let n where n.contains("accessor") || n.contains("gear"):
            return "#667eea"
        default:
            return "#fee140"
        }
    }
}

// MARK: - Foundation Model Service

class FoundationModelService {
    
    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private var session: LanguageModelSession?
    #endif
    
    /// Check if Apple Foundation Models are available
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }
    
    private let systemPrompt = """
    You are PocketPrep AI, an expert packing assistant powered by Apple Intelligence.
    
    RULES:
    1. When the user describes a trip, activity, or event, suggest 12-20 essential items to pack.
    2. ALWAYS organize items into categories using this exact format:
       Category Name: Item1, Item2, Item3
       Each category on a new line. Use a colon after the category name.
    3. Use these category names: Electronics, Clothing, Documents, Toiletries & Hygiene, Food & Snacks, Health & Safety, Outdoor Gear, Accessories, Comfort, Footwear
    4. Only include relevant categories — skip empty ones.
    5. Consider the trip duration, climate, and activity type.
    6. Be specific (e.g. "Hiking boots" not just "Shoes", "SPF 50 Sunscreen" not just "Sunscreen").
    7. For follow-up messages, remember context. If user says "add sunscreen", add it to the relevant category.
    8. Keep responses practical and concise. No lengthy explanations — just the categorized items.
    
    Example output:
    Electronics: Phone Charger, Portable Battery, Headphones
    Clothing: T-Shirts (3), Shorts (2), Light Jacket, Swimsuit
    Toiletries & Hygiene: SPF 50 Sunscreen, Toothbrush, Deodorant
    Health & Safety: First Aid Kit, Insect Repellent
    """
    
    /// Create or reset the conversation session
    func resetSession() {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            session = LanguageModelSession(instructions: systemPrompt)
        }
        #endif
    }
    
    /// Generate categorized packing suggestions using Apple's on-device language model
    func generateSuggestions(for query: String, context: TripContext? = nil) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Create session if needed (for multi-turn)
            if session == nil {
                session = LanguageModelSession(instructions: systemPrompt)
            }
            
            var prompt = query
            if let ctx = context {
                prompt = "\(ctx.promptDescription). \(query)"
            }
            
            let response = try await session!.respond(to: prompt)
            return response.content
        }
        #endif
        throw FoundationModelError.notAvailable
    }
    
    /// Stream responses for real-time chat feel
    func streamResponse(for query: String, context: TripContext? = nil, onUpdate: @escaping (String) -> Void) async throws {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Create session if needed (for multi-turn)
            if session == nil {
                session = LanguageModelSession(instructions: systemPrompt)
            }
            
            var prompt = query
            if let ctx = context {
                prompt = "\(ctx.promptDescription). \(query)"
            }
            
            var fullText = ""
            let stream = session!.streamResponse(to: prompt)
            
            for try await partial in stream {
                fullText = partial.content
                onUpdate(fullText)
            }
            return
        }
        #endif
        throw FoundationModelError.notAvailable
    }
    
    /// Parse structured AI output into categories
    static func parseCategorizedResponse(_ response: String) -> [SuggestionCategory] {
        var categories: [SuggestionCategory] = []
        
        let lines = response.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // Look for "Category: Item1, Item2, Item3"
            if let colonRange = trimmed.range(of: ":") {
                let categoryName = String(trimmed[trimmed.startIndex..<colonRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let itemsString = String(trimmed[colonRange.upperBound...])
                
                let items = itemsString
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                if !items.isEmpty && !categoryName.isEmpty {
                    categories.append(SuggestionCategory(name: categoryName, items: items))
                }
            }
        }
        
        // If parsing failed, treat entire response as flat list under "Suggestions"
        if categories.isEmpty {
            let items = response
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !items.isEmpty {
                categories.append(SuggestionCategory(name: "Suggestions", items: items))
            }
        }
        
        return categories
    }
}

// MARK: - Errors

enum FoundationModelError: LocalizedError {
    case notAvailable
    case sessionFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Intelligence is not available on this device. Requires iPhone 16 or later with Apple Intelligence enabled."
        case .sessionFailed:
            return "Failed to create AI session. Please try again."
        case .invalidResponse:
            return "Could not process AI response."
        }
    }
}
