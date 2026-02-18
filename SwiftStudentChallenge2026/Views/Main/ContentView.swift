//
//  ContentView.swift
//  PocketPrep
//
//  Root view — delegates to MainTabView
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PrepItem.self, PackingList.self])
}
