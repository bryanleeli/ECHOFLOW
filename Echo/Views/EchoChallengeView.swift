//
//  EchoChallengeView.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI

struct EchoChallengeView: View {
    @State private var isRecording = false
    @State private var showComparison = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Main Content
            mainContentView

            Spacer()
        }
        .background(Color(red: 0.102, green: 0.114, blue: 0.180)) // #1a1d2e
        .ignoresSafeArea()
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                // 返回按钮
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            Text("Echo Challenge")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .tracking(-0.3125)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(height: 72)
    }

    private var mainContentView: some View {
        VStack(spacing: 40) {
            Spacer()

            // 声波可视化区域
            soundWaveVisualization

            Spacer()

            // 比较播放按钮
            comparePlaybackButton

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var soundWaveVisualization: some View {
        VStack(spacing: 20) {
            // 大圆形声波可视化
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 232, height: 226)

                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color(red: 0.42, green: 0.48, blue: 0.92)) // #6b7bea
                    .frame(width: 60, height: 60)
            }
            .padding(.top, 56)

            Text("Tap to start recording")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var comparePlaybackButton: some View {
        Button(action: {
            showComparison = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.42, green: 0.48, blue: 0.92))

                Text("Compare Playback")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.42, green: 0.48, blue: 0.92))
                    .tracking(-0.3125)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(Color(red: 0.23, green: 0.29, blue: 0.42)) // #3a4a6a
            .cornerRadius(16)
        }
        .padding(.bottom, 80)
    }
}


#Preview {
    EchoChallengeView()
}