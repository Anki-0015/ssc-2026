//
//  SampleData.swift
//  PocketPrep
//
//  Predefined packing lists and items
//

import Foundation

struct SampleData {
    
    // Available modes (kept for compatibility)
    static let modes = ["College", "Gym", "Travel", "Custom"]
    
    // Template definitions
    static let templates: [(name: String, icon: String, color: String, items: [(name: String, icon: String, category: String)])] = [
        (
            name: "College",
            icon: "book",
            color: "#007AFF",
            items: [
                ("Laptop", "laptopcomputer", "Electronics"),
                ("Notebook", "book.closed", "Accessories"),
                ("ID Card", "person.text.rectangle", "Documents"),
                ("Charger", "cable.connector", "Electronics"),
                ("Pen", "pencil", "Accessories"),
                ("Water Bottle", "waterbottle", "Food & Drinks"),
                ("Calculator", "function", "Electronics"),
                ("Headphones", "headphones", "Electronics")
            ]
        ),
        (
            name: "Gym",
            icon: "dumbbell",
            color: "#FF3B30",
            items: [
                ("Workout Clothes", "tshirt", "Clothing"),
                ("Sneakers", "shoe.2", "Clothing"),
                ("Water Bottle", "waterbottle", "Food & Drinks"),
                ("Towel", "tablecloth", "Accessories"),
                ("Headphones", "headphones", "Electronics"),
                ("Gym Bag", "bag", "Accessories"),
                ("Protein Bar", "fork.knife", "Food & Drinks"),
                ("Deodorant", "drop", "Toiletries")
            ]
        ),
        (
            name: "Travel",
            icon: "airplane",
            color: "#FF9500",
            items: [
                ("Passport", "doc.text", "Documents"),
                ("Phone Charger", "cable.connector", "Electronics"),
                ("Toiletries", "drop", "Toiletries"),
                ("Clothes", "tshirt", "Clothing"),
                ("Wallet", "creditcard", "Accessories"),
                ("Sunglasses", "sunglasses", "Accessories"),
                ("Medications", "cross.case", "Health & Medicine"),
                ("Camera", "camera", "Electronics"),
                ("Travel Pillow", "bed.double", "Accessories"),
                ("Snacks", "fork.knife", "Food & Drinks")
            ]
        ),
        (
            name: "Beach Day",
            icon: "sun.max",
            color: "#FFCC00",
            items: [
                ("Sunscreen", "sun.max.trianglebadge.exclamationmark", "Health & Medicine"),
                ("Towel", "tablecloth", "Accessories"),
                ("Swimsuit", "tshirt", "Clothing"),
                ("Sunglasses", "sunglasses", "Accessories"),
                ("Water Bottle", "waterbottle", "Food & Drinks"),
                ("Sandals", "shoe.2", "Clothing"),
                ("Beach Bag", "bag", "Accessories"),
                ("Book", "book.closed", "Entertainment")
            ]
        ),
        (
            name: "Camping",
            icon: "tent",
            color: "#34C759",
            items: [
                ("Tent", "tent", "Accessories"),
                ("Sleeping Bag", "bed.double", "Accessories"),
                ("Flashlight", "flashlight.on.fill", "Electronics"),
                ("First Aid Kit", "cross.case", "Health & Medicine"),
                ("Water Bottle", "waterbottle", "Food & Drinks"),
                ("Insect Repellent", "ant", "Health & Medicine"),
                ("Matches", "flame", "Accessories"),
                ("Warm Jacket", "tshirt", "Clothing")
            ]
        ),
        (
            name: "Business Trip",
            icon: "briefcase",
            color: "#5856D6",
            items: [
                ("Laptop", "laptopcomputer", "Electronics"),
                ("Business Cards", "person.text.rectangle", "Documents"),
                ("Charger", "cable.connector", "Electronics"),
                ("Formal Wear", "tshirt", "Clothing"),
                ("Notebook", "book.closed", "Accessories"),
                ("ID / Badge", "person.text.rectangle", "Documents"),
                ("Dress Shoes", "shoe.2", "Clothing"),
                ("Portfolio", "folder", "Documents")
            ]
        )
    ]
    
    // Legacy support
    static func defaultItems(for mode: String) -> [(name: String, icon: String, category: String)] {
        templates.first(where: { $0.name == mode })?.items ?? []
    }
}
