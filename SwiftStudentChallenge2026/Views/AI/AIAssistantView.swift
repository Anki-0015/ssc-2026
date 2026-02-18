//
//  AIAssistantView.swift
//  PocketPrep
//
//  Competition-level AI assistant using Apple Foundation Models
//  Stunning gradient branding, animated messages, suggestion chips
//

import SwiftUI
import Combine

struct AIAssistantView: View {
    @ObservedObject var listsViewModel: ListsViewModel
    @StateObject private var chatVM = AIChatViewModel()
    
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showListPicker = false
    @State private var pendingSuggestion = ""
    @State private var showNewListAlert = false
    @State private var newListName = ""
    @State private var selectedSuggestions: Set<String> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !FoundationModelService.isAvailable {
                    unavailableView
                } else {
                    chatView
                }
            }
            .navigationTitle("AI Assistant")
            .toolbar {
                if !chatVM.messages.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation { chatVM.clearChat() }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Chat View
    
    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if chatVM.messages.isEmpty {
                            welcomeSection
                        }
                        
                        ForEach(Array(chatVM.messages.enumerated()), id: \.element.id) { index, message in
                            ChatBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        if !chatVM.suggestions.isEmpty {
                            suggestionsSection
                        }
                        
                        if chatVM.isLoading {
                            TypingIndicator()
                                .padding(.leading, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: chatVM.messages.count) { _, _ in
                    if let last = chatVM.messages.last {
                        withAnimation(.easeOut(duration: 0.35)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            inputBar
        }
    }
    
    // MARK: - Welcome
    
    private var welcomeSection: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 30)
            
            // AI brand icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#667eea") ?? .blue,
                                Color(hex: "#764ba2") ?? .purple,
                                Color(hex: "#f093fb") ?? .pink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .purple.opacity(0.3), radius: 20, y: 8)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 6) {
                Text("PocketPrep AI")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                
                Text("Powered by Apple Intelligence")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(.systemGray6)))
            }
            
            Text("Tell me what you're packing for and\nI'll suggest essential items!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            // Quick prompts
            VStack(spacing: 10) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        sendMessage()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkle")
                                .font(.caption)
                            Text(prompt)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }
    
    private let quickPrompts = [
        "Weekend camping trip in the mountains",
        "Business conference in New York",
        "Beach vacation for a week",
        "First day of college essentials"
    ]
    
    // MARK: - Suggestions
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkle")
                    .font(.caption)
                Text("Suggestions")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    if selectedSuggestions.count == chatVM.suggestions.count {
                        selectedSuggestions.removeAll()
                    } else {
                        selectedSuggestions = Set(chatVM.suggestions)
                    }
                } label: {
                    Text(selectedSuggestions.count == chatVM.suggestions.count ? "Deselect All" : "Select All")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            ForEach(chatVM.suggestions, id: \.self) { suggestion in
                HStack(spacing: 10) {
                    // Selection toggle
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .light)
                        gen.impactOccurred()
                        if selectedSuggestions.contains(suggestion) {
                            selectedSuggestions.remove(suggestion)
                        } else {
                            selectedSuggestions.insert(suggestion)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(selectedSuggestions.contains(suggestion) ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
                                .background(
                                    Circle().fill(selectedSuggestions.contains(suggestion) ? Color.blue : Color.clear)
                                )
                                .frame(width: 22, height: 22)
                            
                            if selectedSuggestions.contains(suggestion) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Image(systemName: chatVM.determineIcon(for: suggestion))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(suggestion)
                        .font(.body)
                    
                    Spacer()
                    
                    Button {
                        pendingSuggestion = suggestion
                        showListPicker = true
                    } label: {
                        Text("Add")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.blue.gradient))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    selectedSuggestions.contains(suggestion) ? Color.blue.opacity(0.4) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // New List button
            Button {
                if selectedSuggestions.isEmpty {
                    selectedSuggestions = Set(chatVM.suggestions)
                }
                newListName = ""
                showNewListAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text(selectedSuggestions.isEmpty ? "New List (All \(chatVM.suggestions.count))" : "New List (\(selectedSuggestions.count) selected)")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .confirmationDialog("Add to List", isPresented: $showListPicker) {
            ForEach(listsViewModel.lists) { list in
                Button(list.name) {
                    let icon = chatVM.determineIcon(for: pendingSuggestion)
                    let category = chatVM.determineCategory(for: pendingSuggestion)
                    listsViewModel.addItem(to: list, name: pendingSuggestion, icon: icon, category: category)
                    chatVM.removeSuggestion(pendingSuggestion)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose which list to add \"\(pendingSuggestion)\" to")
        }
        .alert("Create New List", isPresented: $showNewListAlert) {
            TextField("List name", text: $newListName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                let trimmed = newListName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                
                let itemsToAdd = selectedSuggestions.isEmpty ? chatVM.suggestions : Array(selectedSuggestions)
                let items = itemsToAdd.map { suggestion in
                    (
                        name: suggestion,
                        icon: chatVM.determineIcon(for: suggestion),
                        category: chatVM.determineCategory(for: suggestion)
                    )
                }
                
                listsViewModel.createListWithItems(
                    name: trimmed,
                    icon: "sparkles",
                    colorHex: "#764ba2",
                    items: items
                )
                
                withAnimation {
                    for item in itemsToAdd {
                        chatVM.removeSuggestion(item)
                    }
                    selectedSuggestions.removeAll()
                }
                
                let aiMessage = ChatMessage(
                    text: "Created \"\(trimmed)\" with \(items.count) items!",
                    isUser: false
                )
                chatVM.messages.append(aiMessage)
                
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
            }
        } message: {
            let count = selectedSuggestions.isEmpty ? chatVM.suggestions.count : selectedSuggestions.count
            Text("\(count) suggested item\(count == 1 ? "" : "s") will be added to the new list.")
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("What are you packing for?", text: $inputText)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        canSend
                        ? LinearGradient(colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemGray4)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !chatVM.isLoading
    }
    
    // MARK: - Unavailable View
    
    private var unavailableView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(colors: [.gray, .secondary], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            VStack(spacing: 10) {
                Text("Apple Intelligence Required")
                    .font(.title2.bold())
                
                Text("The AI Assistant requires an iPhone 16 or later\nwith iOS 26+ and Apple Intelligence enabled.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            
            HStack(spacing: 20) {
                RequirementBadge(icon: "iphone", label: "iPhone 16+")
                RequirementBadge(icon: "gear", label: "iOS 26+")
                RequirementBadge(icon: "sparkles", label: "Apple AI")
            }
            
            Text("All AI processing happens on-device\nfor your privacy.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Send
    
    private func sendMessage() {
        guard canSend else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        chatVM.sendMessage(inputText)
        inputText = ""
        isInputFocused = false
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            if !message.isUser {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(message.text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color(.systemGray5))
                )
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotIndex = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 6) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(dotIndex == index ? 1.3 : 0.8)
                        .opacity(dotIndex == index ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.3), value: dotIndex)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .onReceive(timer) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

// MARK: - Requirement Badge

struct RequirementBadge: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
