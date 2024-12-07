//
//  MomentoApp.swift
//  Momento
//
//  Created by Anika Bhatnagar on 10/24/24.
//

import SwiftUI
import Firebase

@main
struct MomentoApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView() // Your main view
        }
    }
}
