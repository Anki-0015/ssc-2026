//
//  NewListSheet.swift
//  PocketPrep
//
//  Create a new custom packing list
//  Polished form with icon & color pickers
//

import SwiftUI

struct NewListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ListsViewModel
    
    @State private var name = ""
    @State private var selectedIcon = "bag.fill"
    @State private var selectedColor = Color.blue
    
    let icons = [
        "bag.fill", "suitcase.fill", "airplane", "car.fill",
        "book.fill", "dumbbell.fill", "tent.2.fill", "sun.max.fill",
        "figure.walk", "briefcase.fill", "graduationcap.fill", "camera.fill",
        "fork.knife", "music.note", "gamecontroller.fill", "theatermasks.fill",
        "cart.fill", "gift.fill", "heart.fill", "star.fill",
        "house.fill", "leaf.fill", "snowflake", "mountain.2.fill"
    ]
    
    let colors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow,
        .green, .mint, .teal, .cyan, .indigo, .brown
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("List Name") {
                    TextField("e.g. Weekend Trip", text: $name)
                        .font(.body)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                let gen = UISelectionFeedbackGenerator()
                                gen.selectionChanged()
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 52, height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? selectedColor : Color(.systemGray6))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                                let gen = UISelectionFeedbackGenerator()
                                gen.selectionChanged()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(color.gradient)
                                        .frame(width: 40, height: 40)
                                    
                                    if selectedColor == color {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Preview
                Section("Preview") {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedColor.gradient.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: selectedIcon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "New List" : name)
                                .font(.body.bold())
                            Text("0 items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createList(
                            name: name,
                            icon: selectedIcon,
                            colorHex: selectedColor.hexString
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }
}
