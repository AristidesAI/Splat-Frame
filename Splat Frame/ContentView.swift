//
//  ContentView.swift
//  Splat Frame
//
//  Created by aristides lintzeris on 21/2/2026.
//

import SwiftUI
import Symbols

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "eye")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Splat Frame")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
