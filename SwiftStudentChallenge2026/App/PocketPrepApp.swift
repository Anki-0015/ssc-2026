//
//  PocketPrepApp.swift
//  PocketPrep
//
//  Smart Packing Assistant — Swift Student Challenge 2026
//  Uses SwiftData, SwiftUI, and Apple Foundation Models
//

import SwiftUI
import SwiftData

@main
struct PocketPrepApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PrepItem.self, PackingList.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("⚠️ SwiftData migration failed: \(error). Creating fresh database.")
            
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
