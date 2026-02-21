//
//  Splat_FrameApp.swift
//  Splat Frame
//
//  Created by aristides lintzeris on 21/2/2026.
//

import SwiftUI

@main
struct Splat_FrameApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
