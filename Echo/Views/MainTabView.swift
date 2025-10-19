//
//  MainTabView.swift
//  WordSpark
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var userInitService = UserInitializationService.shared
    @State private var isInitialized = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyWaveView()
                .tabItem {
                    Image(systemName: "waveform.path")
                    Text("Daily Wave")
                }
                .tag(0)

            EchoChallengeView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Echo Challenge")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.357, green: 0.435, blue: 0.847)) // #5b6fd8
        .onAppear {
            Task { @MainActor in
                if !userInitService.isInitialized {
                    let success = await userInitService.initializeUser()
                    if success {
                        isInitialized = true
                    } else {
                    }
                } else {
                }
            }
        }
    }
}