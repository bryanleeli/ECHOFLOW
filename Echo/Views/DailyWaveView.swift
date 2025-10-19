//
//  DailyWaveView.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI
import AVFoundation
import Combine

// 匹配状态枚举
enum MatchStatus {
    case none // 未匹配
    case correct // 正确匹配
    case incorrect // 错误匹配
}

struct DailyWaveView: View {
    @State private var currentWordIndex = 0
    @State private var currentBackgroundIndex = 0
    @State private var isPlaying = false
    @State private var isDragging = false
    @StateObject private var speechManager = SpeechManager()
    @State private var words: [Word] = []
    @State private var isLoading = true
    @State private var cardTransitionOffset: CGFloat = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var excludedWords: Set<Int32> = []
    @State private var selectedSubstituteIndex: Int? = nil
    @State private var isShowingScenarioCard = false
    @State private var cardRotationAngle: Double = 0
    @State private var scenarioWords: [String] = []
    @State private var scenarioDescriptions: [String] = []
    @State private var matchedWords: [Int: String] = [:]
    @State private var correctAnswers: [Int: String] = [:] // 存储每个场景的正确答案
    @State private var matchStatus: [Int: MatchStatus] = [:] // 存储每个场景的匹配状态
    @State private var draggedWord: String? = nil
    @State private var selectedDropZone: Int? = nil
    @StateObject private var soundManager = SoundManager()

    private let databaseService = DatabaseService.shared

    private let backgroundImages = [
        "daily_wave_bg_1",
        "daily_wave_bg_2",
        "daily_wave_bg_3",
        "daily_wave_bg_4",
        "daily_wave_bg_5"
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image(backgroundImages[currentBackgroundIndex])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .edgesIgnoringSafeArea(.all)

                // 渐变叠加层以保持文字可读性
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .edgesIgnoringSafeArea(.all)

                // 主要内容区域
                VStack(spacing: 0) {
                    Spacer()

                    // 主要内容区域
                    mainContentView

                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .edgesIgnoringSafeArea(.all)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            Task {
                await loadWordsFromDatabase()
                randomizeBackground()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }

                    // 在场景匹配卡片上禁用所有手势
                    if !isShowingScenarioCard {
                        // 只在单词详情卡片上处理滑动
                        // 这里可以添加拖拽逻辑，但现在简化处理
                    }
                }
                .onEnded { value in
                    isDragging = false

                    // 在场景匹配卡片上不处理任何手势
                    if !isShowingScenarioCard {
                        // 在单词详情卡片上处理所有手势
                        // 判断滑动方向
                        if abs(value.translation.height) > abs(value.translation.width) {
                            // 垂直滑动 - 切换单词
                            if value.translation.height > 50 {
                                // 向下滑动，切换到下一个单词
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    switchToNextWord()
                                }
                            } else if value.translation.height < -50 {
                                // 向上滑动，切换到上一个单词
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    switchToPreviousWord()
                                }
                            }
                        } else {
                            // 水平滑动 - 翻转卡片
                            if value.translation.width > 50 {
                                // 向右滑动，切换到另一个卡片
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    flipToScenarioCard()
                                }
                            } else if value.translation.width < -50 {
                                // 向左滑动，切换到另一个卡片
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    flipToScenarioCard()
                                }
                            }
                        }
                    }
                }
        )
        .onTapGesture {
            // 点击时随机切换背景
            withAnimation(.easeInOut(duration: 0.5)) {
                randomizeBackground()
            }
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 20) {
            // 单词详情
            wordDetailView
        }
        .padding(.horizontal, 24)
    }

    private var wordDetailView: some View {
        VStack(spacing: 0) {
            if isLoading {
                Text("Loading amazing words...")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.07)
            } else if !words.isEmpty {
                let currentWord = words[currentWordIndex]

                // 3D翻转卡片容器
                ZStack {
                    // 单词详情卡片（正面）
                    wordDetailCard(for: currentWord)
                        .rotation3DEffect(
                            .degrees(isShowingScenarioCard ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isShowingScenarioCard ? 0 : 1)

                    // 场景匹配卡片（背面）
                    scenarioMatchingCard(for: currentWord)
                        .rotation3DEffect(
                            .degrees(isShowingScenarioCard ? 0 : -180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isShowingScenarioCard ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 120)
                                .scaleEffect(isDragging ? 0.96 : 1.0 * cardScale)
                .animation(.easeInOut(duration: 0.3), value: isDragging)
                .animation(.spring(response: 0.7, dampingFraction: 0.8), value: currentWordIndex)
            }
        }
    }

    private func wordDetailCard(for word: Word) -> some View {
        // 主要内容卡片 - 结构化布局
        VStack(spacing: 0) {
            // 1. 单词板块
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()

                    Text(word.wordString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.02)

                    Spacer()

                    // 不再学习按钮
                    Button(action: {
                        excludeCurrentWord()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                )

                            Text("不再出现")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)

            // 2. 音标和喇叭板块
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    if let ipaPhonetic = word.getIPAPhonetic() {
                        Text("/\(ipaPhonetic)/")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .italic()
                            .foregroundColor(.white.opacity(0.85))
                            .tracking(0.01)

                        // 喇叭图标 - 点击播放发音
                        Button(action: {
                            speechManager.speak(word: word.wordString)
                        }) {
                            Image(systemName: speechManager.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(speechManager.isPlaying ? .white.opacity(0.9) : .white.opacity(0.7))
                                .frame(width: 24, height: 24)
                                .scaleEffect(speechManager.isPlaying ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: speechManager.isPlaying)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 24)

            // 2. 词义板块
            VStack(alignment: .leading, spacing: 12) {
                // 词义内容 - 去掉"词义"标题
                if let partsOfSpeech = word.getPartsOfSpeech() {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(partsOfSpeech.keys.sorted()), id: \.self) { pos in
                            if let meanings = partsOfSpeech[pos], !meanings.isEmpty {
                                // 词性和词义在同一行
                                HStack(alignment: .top, spacing: 8) {
                                    // 词性标签 - 改为小写
                                    Text(pos.lowercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.369, green: 0.769, blue: 0.875))
                                        .tracking(0.08)

                                    // 词义解释
                                    Text(meanings.joined(separator: "；"))
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.95))
                                        .tracking(0.01)
                                        .lineSpacing(3)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 24)

            // 3. 例句板块
            VStack(alignment: .leading, spacing: 12) {
                // 板块标题
                Text("例句")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.02)

                // 例句内容 - 带蓝色边框的矩形区域
                if let sentence = word.getDailySentence() {
                    VStack(alignment: .leading, spacing: 8) {
                        // 蓝色边框矩形区域 - 居中显示
                        HStack {
                            Spacer()
                            highlightedSentenceView(sentence: sentence, word: word.wordString)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.02)
                                .lineSpacing(6)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.369, green: 0.769, blue: 0.875), lineWidth: 1.5)
                                .background(Color(red: 0.369, green: 0.769, blue: 0.875).opacity(0.1))
                        )

                        // 例句使用场景分析
                        if let usageAnalysis = word.getUsageAnalysis() {
                            Text(usageAnalysis)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(0.01)
                                .lineSpacing(3)
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // 分隔线
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 24)

            // 4. 常用替换词板块
            VStack(alignment: .leading, spacing: 12) {
                // 板块标题
                Text("常用替换词")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.02)

                // 替换词按钮 - 灰色圆角矩形，等宽背景框
                if let dailySubstitutes = word.getDailySubstitutes() {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            ForEach(Array(dailySubstitutes.prefix(4).enumerated()), id: \.offset) { index, substituteInfo in
                                Button(action: {
                                    // 点击替换词显示对应的适用场景说明
                                    if selectedSubstituteIndex == index {
                                        selectedSubstituteIndex = nil
                                    } else {
                                        selectedSubstituteIndex = index
                                    }
                                }) {
                                    Text(substituteInfo.substitute)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .tracking(0.01)
                                        .frame(maxWidth: .infinity) // 使用最大宽度，确保等宽
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedSubstituteIndex == index ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedSubstituteIndex == index ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // 显示选中的替换词的适用场景说明
                        if let selectedIndex = selectedSubstituteIndex,
                           selectedIndex < dailySubstitutes.count {
                            HStack {
                                Text(dailySubstitutes[selectedIndex].scenario)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.01)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                Spacer()
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.3), value: selectedSubstituteIndex)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.129, green: 0.141, blue: 0.216).opacity(0.85)) // #212338 半透明
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 12)
    }

    
    // 场景匹配卡片（背面）
    private func scenarioMatchingCard(for word: Word) -> some View {
        VStack(spacing: 0) {
                // 顶部标题及进度区域 - 添加滑动支持
                VStack(spacing: 6) {
                    HStack {
                        // 返回按钮
                        Button(action: {
                            flipToWordCard()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        Text("场景匹配")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(matchedWords.count)/4")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            // 检测水平滑动方向
                            if abs(value.translation.width) > abs(value.translation.height) {
                                if value.translation.width > 0 {
                                    // 向右滑动 - 翻回单词详情
                                    flipToWordCard()
                                } else {
                                    // 向左滑动 - 翻到下一个单词并生成新场景
                                    moveToNextWord()
                                    flipToScenarioCard()
                                }
                            }
                        }
                )

                // 中间场景描述区
                VStack(spacing: 6) {
                    ForEach(0..<scenarioDescriptions.count, id: \.self) { index in
                        scenarioModule(index: index, description: scenarioDescriptions[index])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            // 检测水平滑动方向
                            if abs(value.translation.width) > abs(value.translation.height) {
                                if value.translation.width > 0 {
                                    // 向右滑动 - 翻回单词详情
                                    flipToWordCard()
                                } else {
                                    // 向左滑动 - 翻到下一个单词并生成新场景
                                    moveToNextWord()
                                    flipToScenarioCard()
                                }
                            }
                        }
                )

                // 底部选项区
                VStack(spacing: 8) {
                    // 选项按钮
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(scenarioWords, id: \.self) { wordText in
                            draggableWord(wordText)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.129, green: 0.141, blue: 0.216).opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 12)
        .onAppear {
            setupScenarios(for: word)
        }
    }

    // 场景模块组件 - 整个框作为拖拽放置区
    private func scenarioModule(index: Int, description: String) -> some View {
        let hasMatchedWord = matchedWords[index] != nil
        let isSelected = selectedDropZone == index
        let isDragging = draggedWord != nil

        let backgroundColor: Color
        let strokeColor: Color
        let lineWidth: CGFloat

        if hasMatchedWord {
            // 根据匹配状态设置颜色
            let status = matchStatus[index] ?? .none
            switch status {
            case .correct:
                backgroundColor = Color.green.opacity(0.2)
                strokeColor = Color.green
            case .incorrect:
                backgroundColor = Color.red.opacity(0.2)
                strokeColor = Color.red
            case .none:
                backgroundColor = Color(red: 0.369, green: 0.769, blue: 0.875).opacity(0.2)
                strokeColor = Color(red: 0.369, green: 0.769, blue: 0.875)
            }
            lineWidth = 2
        } else if isSelected {
            backgroundColor = Color(red: 0.369, green: 0.769, blue: 0.875).opacity(0.15)
            strokeColor = Color(red: 0.369, green: 0.769, blue: 0.875)
            lineWidth = 3
        } else if isDragging {
            backgroundColor = Color.white.opacity(0.12)
            strokeColor = Color.white.opacity(0.4)
            lineWidth = 2
        } else {
            backgroundColor = Color.white.opacity(0.06)
            strokeColor = Color.white.opacity(0.15)
            lineWidth = 1
        }

        return HStack(spacing: 12) {
            // 左侧拖拽区 - 加长
            ZStack {
                if let wordWithPrefix = matchedWords[index] {
                    // 已匹配的单词
                    matchedWordView(wordText: wordWithPrefix, index: index)
                } else {
                    // 空的拖拽区提示
                    VStack(spacing: 2) {
                        Image(systemName: isSelected ? "plus.circle.fill" : "arrow.right.circle.dashed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : (isDragging ? .white.opacity(0.6) : .white.opacity(0.4)))

                        Text("拖拽")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .scaleEffect(isSelected ? 1.05 : (isDragging ? 1.02 : 1.0))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
            .frame(width: 80, height: 48) // 加长拖拽区
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(strokeColor.opacity(0.6), lineWidth: 1)
                    )
            )

            // 右侧场景描述
            Text(description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(0.8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(height: 60) // 固定高度
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(strokeColor, lineWidth: lineWidth)
                )
        )
        .onTapGesture {
            if matchedWords[index] == nil {
                // 点击选择或取消选择
                if selectedDropZone == index {
                    selectedDropZone = nil
                } else {
                    selectedDropZone = index
                }
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            // 处理拖拽放下
            if matchedWords[index] == nil {
                // 从provider中获取拖拽的数据
                for provider in providers {
                    provider.loadObject(ofClass: String.self) { string, error in
                        if let wordText = string as? String {
                            Task { @MainActor in
                                matchedWords[index] = wordText
                                // 检查匹配是否正确
                                checkMatch(scenarioIndex: index)
                            }
                        }
                    }
                }
            }
            return true
        }
    }

    // 获取场景背景色
    private func getScenarioBackgroundColor(index: Int) -> Color {
        let status = matchStatus[index] ?? .none

        switch status {
        case .none:
            return Color.white.opacity(0.06) // 默认背景色
        case .correct:
            return Color.green.opacity(0.2) // 正确匹配显示绿色
        case .incorrect:
            return Color.red.opacity(0.2) // 错误匹配显示红色
        }
    }

    
    // 已匹配单词的视图组件
    private func matchedWordView(wordText: String, index: Int) -> some View {
        HStack(spacing: 3) {
            // 显示单词（不再有前缀）
            Text(wordText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Button(action: {
                matchedWords.removeValue(forKey: index)
                matchStatus[index] = MatchStatus.none // 重置匹配状态
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.369, green: 0.769, blue: 0.875))
        )
    }

    
    // 可拖拽的单词
    private func draggableWord(_ text: String) -> some View {
        let isMatched = matchedWords.values.contains(text) // 检查单词是否已匹配

        return Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isMatched ? .gray : .white) // 已匹配的单词显示为灰色
            .frame(maxWidth: .infinity) // 使用最大宽度，确保所有框宽度一致
            .frame(height: 44) // 固定高度
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isMatched ?
                        Color.gray.opacity(0.3) : // 已匹配的单词使用灰色背景
                        (draggedWord == text ? Color(red: 0.469, green: 0.769, blue: 0.875) : Color(red: 0.369, green: 0.769, blue: 0.875))
                    )
            )
            .scaleEffect(draggedWord == text && !isMatched ? 1.05 : 1.0) // 只有未匹配的单词才有缩放效果
            .opacity(draggedWord == text && !isMatched ? 0.9 : (isMatched ? 0.6 : 1.0)) // 已匹配的单词透明度降低
            .shadow(color: (draggedWord == text && !isMatched) ? .black.opacity(0.3) : .clear, radius: 6, x: 0, y: 3) // 减少阴影
            .allowsHitTesting(!isMatched) // 已匹配的单词不允许交互
            .onTapGesture {
                if !isMatched {
                    // 点击时分配到第一个空的拖拽区
                    assignWordToSelectedDropZone(wordText: text)
                }
            }
            .draggable(isMatched ? "" : text) { // 已匹配的单词不能拖拽
                // 拖拽时的预览
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44) // 固定预览尺寸
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.469, green: 0.769, blue: 0.875))
                    )
                    .opacity(0.8)
            }
    }

    // 单词选项按钮
    private func wordOptionButton(_ text: String) -> some View {
        Button(action: {
            // 点击单词按钮时，分配到第一个空的拖拽区
            assignWordToFirstEmptyDropZone()
        }) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.369, green: 0.769, blue: 0.875))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 分配单词到指定索引的拖拽区
    
    // 分配单词到选中的拖拽区
    private func assignWordToSelectedDropZone(wordText: String) {
        var assignedIndex: Int?

        if let selectedIndex = selectedDropZone, matchedWords[selectedIndex] == nil {
            // 如果有选中的拖拽区，分配到选中的拖拽区
            matchedWords[selectedIndex] = wordText
            assignedIndex = selectedIndex
            selectedDropZone = nil
        } else {
            // 否则分配到第一个空的拖拽区
            for i in 0..<4 {
                if matchedWords[i] == nil {
                    matchedWords[i] = wordText
                    assignedIndex = i
                    break
                }
            }
        }

        // 检查匹配是否正确
        if let index = assignedIndex {
            checkMatch(scenarioIndex: index)
        }
    }

    // 检查匹配是否正确
    private func checkMatch(scenarioIndex: Int) {
        guard let placedWord = matchedWords[scenarioIndex],
              let correctAnswer = correctAnswers[scenarioIndex] else {
            return
        }

        if placedWord == correctAnswer {
            matchStatus[scenarioIndex] = .correct
        } else {
            matchStatus[scenarioIndex] = .incorrect
        }
    }

    // 分配单词到第一个空的拖拽区
    private func assignWordToFirstEmptyDropZone() {
        let availableWords = scenarioWords.filter { word in
            !matchedWords.values.contains(word)
        }
        if let firstWord = availableWords.first {
            assignWordToSelectedDropZone(wordText: firstWord)
        }
    }

    // 设置场景数据
    private func setupScenarios(for word: Word) {
        // 重置数据
        matchedWords.removeAll()

        // 准备单词和描述
        var words: [String] = [word.wordString]
        var descriptions: [String] = []

        // 获取当前单词的中文词义作为场景描述
        if let meaning = word.getChineseMeaning() {
            descriptions.append(meaning)
        } else if let sentence = word.getDailySentence() {
            // 如果没有中文词义，则使用例句
            descriptions.append(sentence)
        }

        // 获取替换词和描述
        if let substitutes = word.getDailySubstitutes() {
            for substitute in substitutes.prefix(3) {
                words.append(substitute.substitute)
                descriptions.append(substitute.scenario)
            }
        }

        // 确保有4个单词和4个描述
        while words.count < 4 {
            words.append("Word \(words.count + 1)")
        }
        while descriptions.count < 4 {
            descriptions.append("Scenario description for word \(descriptions.count + 1)")
        }

        // 随机打乱顺序
        let shuffledIndices = (0..<4).shuffled()

        scenarioWords = []

        for (index, originalIndex) in shuffledIndices.enumerated() {
            // 不再添加前缀，直接使用原始单词
            let word = words[originalIndex]
            scenarioWords.append(word)
        }

        scenarioDescriptions = shuffledIndices.map { descriptions[$0] }

        // 设置正确答案 - 每个场景索引对应的正确单词
        correctAnswers.removeAll()
        matchStatus.removeAll()

        for (scenarioIndex, originalWordIndex) in shuffledIndices.enumerated() {
            let correctWord = words[originalWordIndex]
            correctAnswers[scenarioIndex] = correctWord
            matchStatus[scenarioIndex] = MatchStatus.none
        }
    }

    // 获取当前显示的单词
    private func getCurrentWord() -> Word {
        return words[currentWordIndex]
    }

    // 移动到下一个单词（无动画，用于场景匹配页面滑动）
    private func moveToNextWord() {
        // 重置匹配状态
        matchedWords.removeAll()
        matchStatus.removeAll()

        // 跳过已排除的单词
        var nextIndex = (currentWordIndex + 1) % words.count
        var attempts = 0
        while attempts < words.count && excludedWords.contains(words[nextIndex].id) {
            nextIndex = (nextIndex + 1) % words.count
            attempts += 1
        }

        if attempts < words.count {
            currentWordIndex = nextIndex
        }
    }

    // 翻转到场景匹配卡片
    private func flipToScenarioCard() {
        soundManager.playSwipeSound()

        // 根据当前单词生成场景匹配内容
        let currentWord = getCurrentWord()
        setupScenarios(for: currentWord)

        withAnimation(.easeInOut(duration: 0.6)) {
            isShowingScenarioCard = true
        }
    }

    // 翻转到单词详情卡片
    private func flipToWordCard() {
        soundManager.playSwipeSound()
        withAnimation(.easeInOut(duration: 0.6)) {
            isShowingScenarioCard = false
        }
    }

    // 随机切换背景图片
    private func randomizeBackground() {
        let newIndex = Int.random(in: 0..<backgroundImages.count)
        currentBackgroundIndex = newIndex
    }

    // 手动切换背景图片的函数（可添加手势触发）
    private func switchToNextBackground() {
        currentBackgroundIndex = (currentBackgroundIndex + 1) % backgroundImages.count
    }

    private func switchToPreviousBackground() {
        currentBackgroundIndex = currentBackgroundIndex == 0 ? backgroundImages.count - 1 : currentBackgroundIndex - 1
    }

    // 辅助方法：在例句中高亮显示目标单词（简化版本）
    private func highlightedSentenceView(sentence: String, word: String) -> Text {
        // 简化实现：暂时不添加背景色，只保持居中显示
        // 如果需要高亮，可以使用 AttributedString 或者其他方式
        Text(sentence)
    }

    
    // 切换到下一个单词
    private func switchToNextWord() {
        // 播放划动音效
        soundManager.playSwipeSound()

        // 重置状态
        selectedSubstituteIndex = nil
        isShowingScenarioCard = false
        matchedWords.removeAll()

        // 跳过已排除的单词
        var nextIndex = (currentWordIndex + 1) % words.count
        var attempts = 0
        while attempts < words.count && excludedWords.contains(words[nextIndex].id) {
            nextIndex = (nextIndex + 1) % words.count
            attempts += 1
        }

        if attempts >= words.count {
            return // 所有单词都被排除了
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            cardTransitionOffset = -UIScreen.main.bounds.height * 0.25
            cardScale = 0.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentWordIndex = nextIndex

            // 新卡片从屏幕上方出现（与当前卡片消失方向相同，都是从上方）
            cardTransitionOffset = -UIScreen.main.bounds.height * 0.25
            cardScale = 0.3

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.easeOut(duration: 0.3)) {
                    cardTransitionOffset = 0
                    cardScale = 1.0
                }
            }
        }
    }

    // 切换到上一个单词
    private func switchToPreviousWord() {
        // 播放划动音效
        soundManager.playSwipeSound()

        // 重置状态
        selectedSubstituteIndex = nil
        isShowingScenarioCard = false
        matchedWords.removeAll()

        // 跳过已排除的单词
        var prevIndex = currentWordIndex == 0 ? words.count - 1 : currentWordIndex - 1
        var attempts = 0
        while attempts < words.count && excludedWords.contains(words[prevIndex].id) {
            prevIndex = prevIndex == 0 ? words.count - 1 : prevIndex - 1
            attempts += 1
        }

        if attempts >= words.count {
            return // 所有单词都被排除了
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            cardTransitionOffset = UIScreen.main.bounds.height * 0.25
            cardScale = 0.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentWordIndex = prevIndex

            // 新卡片从屏幕下方出现（与当前卡片消失方向相同，都是从下方）
            cardTransitionOffset = UIScreen.main.bounds.height * 0.25
            cardScale = 0.3

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.easeOut(duration: 0.3)) {
                    cardTransitionOffset = 0
                    cardScale = 1.0
                }
            }
        }
    }

    // 排除当前单词
    private func excludeCurrentWord() {
        excludedWords.insert(words[currentWordIndex].id)

        // 如果当前单词被排除，移动到下一个单词
        if let nextIndex = getNextValidWordIndex() {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentWordIndex = nextIndex
            }
        }
    }

    // 获取下一个有效的单词索引（排除已标记的单词）
    private func getNextValidWordIndex() -> Int? {
        var nextIndex = (currentWordIndex + 1) % words.count
        var attempts = 0

        while attempts < words.count {
            if !excludedWords.contains(words[nextIndex].id) {
                return nextIndex
            }
            nextIndex = (nextIndex + 1) % words.count
            attempts += 1
        }

        return nil // 所有单词都被排除了
    }

    // 从数据库加载单词
    @MainActor
    private func loadWordsFromDatabase() async {
        isLoading = true

        // 获取随机单词用于每日学习
        words = databaseService.getRandomWords(count: 20)

        // 如果没有获取到单词，创建一些默认单词
        if words.isEmpty {
            // 创建一些示例单词数据（使用ARPAbet格式）
            words = [
                Word(
                    id: 1,
                    wordString: "amazing",
                    phonetic: "AH0 MEY1 ZIH0 NG",
                    partsOfSpeech: "[{\"pos\": \"adj.\", \"meanings\": [\"causing great surprise or wonder; astonishing\"]}]",
                    exampleSentence: "It was an amazing performance that left the audience speechless.",
                    dailySubstitutes: "[{\"substitute\": \"wonderful\", \"scenario\": \"令人惊叹的，极好的\"}, {\"substitute\": \"fantastic\", \"scenario\": \"极好的，了不起的\"}]",
                    usageAnalysis: "Used to express strong positive reaction or surprise"
                ),
                Word(
                    id: 2,
                    wordString: "journey",
                    phonetic: "JH ER1 N IY0",
                    partsOfSpeech: "[{\"pos\": \"n.\", \"meanings\": [\"an act of traveling from one place to another\"]}]",
                    exampleSentence: "The journey to fluency requires dedication and consistent practice.",
                    dailySubstitutes: "[{\"substitute\": \"trip\", \"scenario\": \"通常指短途旅行或出差\"}, {\"substitute\": \"voyage\", \"scenario\": \"通常指海上长途旅行\"}]",
                    usageAnalysis: "Used to describe the process of moving between places"
                ),
                Word(
                    id: 3,
                    wordString: "discover",
                    phonetic: "D IH0 S K AH1 V ER0",
                    partsOfSpeech: "[{\"pos\": \"v.\", \"meanings\": [\"find something unexpectedly or in the course of a search\"]}]",
                    exampleSentence: "Every day I discover new words that expand my vocabulary.",
                    dailySubstitutes: "[{\"substitute\": \"find\", \"scenario\": \"找到丢失的东西或发现答案\"}, {\"substitute\": \"uncover\", \"scenario\": \"揭露隐藏的真相或秘密\"}]",
                    usageAnalysis: "Used to describe the act of finding something new"
                )
            ]
        }

        isLoading = false
        currentWordIndex = 0

        // 确保初始单词没有被排除
        while !words.isEmpty && excludedWords.contains(words[currentWordIndex].id) {
            currentWordIndex = (currentWordIndex + 1) % words.count
        }
    }
}

// MARK: - Sound Manager
@MainActor
class SoundManager: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
    }

    func playSwipeSound() {
        // 使用系统音效播放划动声音
        let systemSoundID: SystemSoundID = 1104
        AudioServicesPlaySystemSound(systemSoundID)
        print("🎵 播放划动音效")
    }
}

// MARK: - Speech Manager
@MainActor
class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isPlaying = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(word: String) {
        print("🔊 尝试播放单词发音: \(word)")

        // 停止当前播放
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: word)

        // 检查可用的语音
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        print("📢 可用语音数量: \(availableVoices.count)")

        // 设置英语发音 - 使用更灵活的方式
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
            print("🇺🇸 使用美式英语语音")
        } else if let voice = AVSpeechSynthesisVoice(language: "en-GB") {
            utterance.voice = voice
            print("🇬🇧 使用英式英语语音")
        } else {
            print("⚠️ 没有找到英语语音，使用默认语音")
        }

        utterance.rate = 0.5 // 语速稍慢，便于学习
        utterance.pitchMultiplier = 1.0 // 正常音调
        utterance.volume = 1.0 // 正常音量

        print("🎵 开始播放发音")
        synthesizer.speak(utterance)
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🎤 语音播放开始")
        Task { @MainActor in
            isPlaying = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ 语音播放完成")
        Task { @MainActor in
            isPlaying = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("❌ 语音播放被取消")
        Task { @MainActor in
            isPlaying = false
        }
    }
}

#Preview {
    DailyWaveView()
}