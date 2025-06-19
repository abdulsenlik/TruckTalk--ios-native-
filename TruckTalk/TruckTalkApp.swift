//
//  TruckTalkApp.swift
//  TruckTalk
//
//  Created by Senlik on 6/18/25.
//

import SwiftUI

@main
struct TruckTalkApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var dataService = DataService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environmentObject(dataService)
        }
    }
}
