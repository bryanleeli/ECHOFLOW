//
//  LearningView.swift
//  WordSpark
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI
import SwiftData

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vocabularySets: [VocabularySet]
    @State private var selectedMode: LearningMode = .flashcard
    @State private var selectedSet: VocabularySet?
    @State private var startLearning = false

    enum LearningMode: String, CaseIterable {
        case flashcard = "Flashcards"
        case quiz = "Quiz"
        case practice = "Practice"
        case review = "Review"

        var icon: String {
            switch self {
            case .flashcard: return "rectangle.stack.fill"
            case .quiz: return "questionmark.circle.fill"
            case .practice: return "pencil.and.outline"
            case .review: return "arrow.clockwise"
            }
        }

        var description: String {
            switch self {
            case .flashcard: return "Classic flashcard learning"
            case .quiz: return "Test your knowledge"
            case .practice: return "Write and practice"
            case .review: return "Review learned words"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 学习模式选择
                    learningModeSection

                    // 词汇集选择
                    vocabularySetSection

                    // 开始学习按钮
                    startLearningButton

                    // 今日目标
                    dailyGoalsSection
                }
                .padding()
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $startLearning) {
            if let set = selectedSet {
                LearningSessionView(set: set, mode: selectedMode)
            }
        }
    }

    private var learningModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Learning Mode")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(LearningMode.allCases, id: \.self) { mode in
                    LearningModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode
                    ) {
                        selectedMode = mode
                    }
                }
            }
        }
    }

    private var vocabularySetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Vocabulary Set")
                .font(.headline)
                .fontWeight(.semibold)

            if vocabularySets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Vocabulary Sets")
                        .font(.headline)
                    Text("Create a vocabulary set first")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(vocabularySets, id: \.id) { set in
                        VocabularySetSelectionCard(
                            set: set,
                            isSelected: selectedSet?.id == set.id
                        ) {
                            selectedSet = set
                        }
                    }
                }
            }
        }
    }

    private var startLearningButton: some View {
        Button(action: {
            if selectedSet != nil {
                startLearning = true
            }
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("Start Learning")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedSet != nil ? Color.blue : Color.gray)
            )
            .foregroundColor(.white)
        }
        .disabled(selectedSet == nil)
    }

    private var dailyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Goals")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                GoalProgressRow(
                    title: "Words to Learn",
                    current: 5,
                    target: 10,
                    color: .blue
                )

                GoalProgressRow(
                    title: "Review Sessions",
                    current: 2,
                    target: 3,
                    color: .green
                )

                GoalProgressRow(
                    title: "Practice Time",
                    current: 8,
                    target: 15,
                    color: .orange,
                    unit: "min"
                )
            }
        }
    }
}

struct LearningModeCard: View {
    let mode: LearningView.LearningMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(mode.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VocabularySetSelectionCard: View {
    let set: VocabularySet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: set.icon)
                        .foregroundColor(Color(set.color))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Text(set.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack {
                    Text("\(set.words.count) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalProgressRow: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color

    init(title: String, current: Int, target: Int, color: Color, unit: String = "") {
        self.title = title
        self.current = current
        self.target = target
        self.unit = unit
        self.color = color
    }

    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(current)/\(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.5)
        }
    }
}

struct LearningSessionView: View {
    let set: VocabularySet
    let mode: LearningView.LearningMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentWordIndex = 0
    @State private var showAnswer = false
    @State private var session: LearningSession
    @State private var isCompleted = false

    init(set: VocabularySet, mode: LearningView.LearningMode) {
        self.set = set
        self.mode = mode
        _session = State(initialValue: LearningSession())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 进度指示器
                LearningProgressIndicatorView(
                    current: currentWordIndex + 1,
                    total: set.words.count
                )

                // 学习内容
                if currentWordIndex < set.words.count {
                    let word = set.words[currentWordIndex]

                    switch mode {
                    case .flashcard:
                        FlashcardView(
                            word: word,
                            showAnswer: $showAnswer,
                            onFlip: { showAnswer.toggle() }
                        )
                    case .quiz:
                        QuizView(word: word, words: set.words)
                    case .practice:
                        PracticeView(word: word)
                    case .review:
                        ReviewView(word: word)
                    }
                }

                // 控制按钮
                controlButtons
            }
            .padding()
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") { dismiss() }
                }
            }
        }
        .onAppear {
            session.startTime = Date()
        }
        .sheet(isPresented: $isCompleted) {
            LearningCompletedView(session: session)
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                if currentWordIndex > 0 {
                    currentWordIndex -= 1
                    showAnswer = false
                }
            }
            .disabled(currentWordIndex == 0)

            Spacer()

            Button("Next") {
                if currentWordIndex < set.words.count - 1 {
                    currentWordIndex += 1
                    showAnswer = false
                } else {
                    session.endSession()
                    isCompleted = true
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

struct FlashcardView: View {
    let word: WordItem
    @Binding var showAnswer: Bool
    let onFlip: () -> Void

    var body: some View {
        Button(action: onFlip) {
            VStack(spacing: 20) {
                if !showAnswer {
                    VStack(spacing: 16) {
                        Text(word.word)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        if let pronunciation = word.pronunciation {
                            Text(pronunciation)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Text(word.definition)
                            .font(.title2)
                            .multilineTextAlignment(.center)

                        if let example = word.example {
                            Text("\"\(example)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LearningProgressIndicatorView: View {
    let current: Int
    let total: Int

    private var progress: Double {
        Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(current) of \(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 1.5)
        }
    }
}

struct LearningCompletedView: View {
    let session: LearningSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Learning Completed!")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    StatRow(title: "Words Studied", value: "\(session.wordsStudied)")
                    StatRow(title: "Correct Answers", value: "\(session.correctAnswers)")
                    StatRow(title: "Time Spent", value: formatTime(session.totalTime))
                }

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
            }
            .padding()
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct QuizView: View {
    let word: WordItem
    let words: [WordItem]

    var body: some View {
        VStack {
            Text("Quiz Mode")
                .font(.title2)
                .fontWeight(.bold)

            Text("What is the definition of:")
                .font(.headline)
                .padding()

            Text(word.word)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // 这里应该添加选项按钮
            Text("Quiz options coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct PracticeView: View {
    let word: WordItem
    @State private var userAnswer = ""

    var body: some View {
        VStack {
            Text("Practice Mode")
                .font(.title2)
                .fontWeight(.bold)

            Text("Write the definition of:")
                .font(.headline)
                .padding()

            Text(word.word)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            TextField("Type the definition here...", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Check Answer") {
                // 检查答案的逻辑
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ReviewView: View {
    let word: WordItem

    var body: some View {
        VStack(spacing: 20) {
            Text("Review Mode")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text(word.word)
                    .font(.title)
                    .fontWeight(.bold)

                if let pronunciation = word.pronunciation {
                    Text(pronunciation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(word.definition)
                    .font(.body)
                    .multilineTextAlignment(.center)

                if let example = word.example {
                    Text("\"\(example)\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.blue)
                }
            }

            HStack {
                Button("Not Learned") {
                    // 标记为未学会
                }
                .buttonStyle(.bordered)

                Button("Learned") {
                    // 标记为已学会
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    LearningView()
        .modelContainer(for: [VocabularySet.self, WordItem.self, LearningSession.self], inMemory: true)
}