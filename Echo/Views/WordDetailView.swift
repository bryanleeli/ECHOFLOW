//
//  WordDetailView.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI

struct WordDetailView: View {
    let word: WordItem
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 主要内容区域
            mainContentView

            Spacer()
        }
        .background(Color(red: 0.102, green: 0.122, blue: 0.180)) // #1a1f2e
        .ignoresSafeArea()
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // 单词卡片
            wordCardView
                .padding(.horizontal, 16)
                .padding(.top, 32)

            Spacer()
        }
    }

    private var wordCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 单词标题和发音
            VStack(alignment: .leading, spacing: 16) {
                // 单词
                Text(word.word)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(.white)
                    .tracking(0.352)

                // 发音和播放按钮
                HStack(spacing: 12) {
                    Text(word.pronunciation ?? "/ˈwiːk.end/")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
                        .tracking(-0.44)

                    Button(action: {
                        playPronunciation()
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }

            // 词性和中文释义
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text("n.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0, green: 0.827, blue: 0.949)) // #00d3f2
                        .tracking(-0.3125)

                    Text("周末")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.82, green: 0.835, blue: 0.863)) // #d1d5dc
                        .tracking(-0.3125)
                }

                HStack(spacing: 12) {
                    Text("v.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0, green: 0.827, blue: 0.949)) // #00d3f2
                        .tracking(-0.3125)

                    Text("度周末")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.82, green: 0.835, blue: 0.863)) // #d1d5dc
                        .tracking(-0.3125)
                }
            }

            // 例句
            exampleSentenceView

            // AI解释
            aiExplanationView
        }
        .padding(24)
        .background(Color(red: 0.176, green: 0.208, blue: 0.282)) // #2d3548
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 25, x: 0, y: 12)
    }

    private var exampleSentenceView: some View {
        HStack(spacing: 12) {
            // 引号图标
            Image(systemName: "quote.opening")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0, green: 0.827, blue: 0.949)) // #00d3f2

            // 例句文本
            Text(word.example ?? "I can't wait for the weekend to relax.")
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundColor(Color(red: 0, green: 0.827, blue: 0.949)) // #00d3f2
                .tracking(-0.44)
                .italic()

            Spacer()

            // 引号图标
            Image(systemName: "quote.closing")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0, green: 0.827, blue: 0.949)) // #00d3f2
        }
        .padding(.vertical, 16)
    }

    private var aiExplanationView: some View {
        Text(aiExplanation)
            .font(.system(size: 16))
            .foregroundColor(Color(red: 0.82, green: 0.835, blue: 0.863)) // #d1d5dc
            .tracking(-0.3125)
            .lineSpacing(4)
            .padding(.top, 8)
    }

    
    private var aiExplanation: String {
        return "AI explanation: In this sentence, \"\(word.word.lowercased())\" refers to the period of Saturday and Sunday, a time for leisure."
    }

    private func playPronunciation() {
        // 播放单词发音的逻辑
        withAnimation(.easeInOut(duration: 0.3)) {
            isPlaying.toggle()
        }

        // 这里可以集成实际的语音播放功能
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPlaying.toggle()
            }
        }
    }
}

#Preview {
    NavigationView {
        WordDetailView(word: WordItem(word: "weekend", definition: "The period of Saturday and Sunday", category: "Time"))
    }
    .preferredColorScheme(.dark)
}