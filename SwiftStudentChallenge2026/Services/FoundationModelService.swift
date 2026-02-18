//
//  FoundationModelService.swift
//  PocketPrep
//
//  Apple Foundation Models integration
//  Uses on-device LLM for AI-powered packing suggestions
//  Available on iPhone 16+ with Apple Intelligence
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Foundation Model Service

class FoundationModelService {
    
    /// Check if Apple Foundation Models are available
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }
    
    /// Generate packing suggestions using Apple's on-device language model
    func generateSuggestions(for query: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let session = LanguageModelSession(
                instructions: """
                You are PocketPrep, a helpful packing assistant. 
                When the user describes a trip or activity, suggest 4-6 essential items to pack.
                Format: Return items as a simple comma-separated list. 
                Keep it concise. Only physical items.
                Example: "Laptop, Charger, Notebook, Pen, Water Bottle, Headphones"
                """
            )
            
            let response = try await session.respond(to: query)
            return response.content
        }
        #endif
        throw FoundationModelError.notAvailable
    }
    
    /// Stream responses for real-time chat feel
    func streamResponse(for query: String, onUpdate: @escaping (String) -> Void) async throws {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let session = LanguageModelSession(
                instructions: """
                You are PocketPrep, a friendly and knowledgeable packing assistant.
                Help users decide what to pack for their trips and activities.
                Be conversational but concise. Suggest practical items.
                When suggesting items, format them clearly so users can easily add them.
                """
            )
            
            var fullText = ""
            let stream = session.streamResponse(to: query)
            
            for try await partial in stream {
                fullText = partial.content
                onUpdate(fullText)
            }
            return
        }
        #endif
        throw FoundationModelError.notAvailable
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
