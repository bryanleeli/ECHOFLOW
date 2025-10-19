//
//  ProgressView.swift
//  WordSpark
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI
import Charts
import SwiftData

struct LearningProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var learningSessions: [LearningSession]
    @Query private var words: [WordItem]
    @State private var selectedPeriod: TimePeriod = .week

    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 总览统计
                    overviewStats

                    // 时间段选择
                    periodSelector

                    // 学习进度图表
                    learningChart

                    // 词汇掌握情况
                    vocabularyMastery

                    // 成就徽章
                    achievementsSection

                    // 学习习惯分析
                    studyHabits
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var overviewStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Overview")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                OverviewStatCard(
                    title: "Total Words",
                    value: "\(totalWords)",
                    icon: "book.fill",
                    color: .blue,
                    trend: "+12%"
                )

                OverviewStatCard(
                    title: "Words Learned",
                    value: "\(wordsLearned)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: "+8%"
                )

                OverviewStatCard(
                    title: "Study Streak",
                    value: "\(studyStreak)",
                    icon: "flame.fill",
                    color: .orange,
                    trend: "+2 days"
                )

                OverviewStatCard(
                    title: "Accuracy",
                    value: "\(accuracy)%",
                    icon: "target",
                    color: .purple,
                    trend: "+5%"
                )
            }
        }
    }

    private var periodSelector: some View {
        HStack {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedPeriod == period ? Color.blue : Color(.systemGray6))
                        )
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                }
            }
        }
    }

    private var learningChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Activity")
                .font(.headline)
                .fontWeight(.semibold)

            // 这里应该使用Charts框架显示真实数据
            VStack(spacing: 12) {
                ForEach(sampleChartData, id: \.day) { data in
                    HStack {
                        Text(data.day)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * data.progress, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)

                        Text("\(data.words)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }

    private var vocabularyMastery: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vocabulary Mastery")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                MasteryRow(
                    title: "Easy Words",
                    count: easyWordsCount,
                    total: totalWords,
                    color: .green
                )

                MasteryRow(
                    title: "Medium Words",
                    count: mediumWordsCount,
                    total: totalWords,
                    color: .orange
                )

                MasteryRow(
                    title: "Hard Words",
                    count: hardWordsCount,
                    total: totalWords,
                    color: .red
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }

    private var studyHabits: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Habits")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                HabitRow(
                    title: "Best Study Time",
                    value: "Evening (6-9 PM)",
                    icon: "clock.fill",
                    color: .blue
                )

                HabitRow(
                    title: "Average Session",
                    value: "12 minutes",
                    icon: "timer",
                    color: .green
                )

                HabitRow(
                    title: "Most Productive Day",
                    value: "Tuesday",
                    icon: "calendar.circle.fill",
                    color: .orange
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }

    // 计算属性
    private var totalWords: Int { words.count }
    private var wordsLearned: Int { words.filter { $0.isLearned }.count }
    private var studyStreak: Int { 7 } // 示例值
    private var accuracy: Int { 85 } // 示例值
    private var easyWordsCount: Int { words.filter { $0.difficulty == .easy }.count }
    private var mediumWordsCount: Int { words.filter { $0.difficulty == .medium }.count }
    private var hardWordsCount: Int { words.filter { $0.difficulty == .hard }.count }

    // 示例数据
    private var sampleChartData: [ChartData] {
        [
            ChartData(day: "Mon", words: 15, progress: 0.75),
            ChartData(day: "Tue", words: 20, progress: 1.0),
            ChartData(day: "Wed", words: 8, progress: 0.4),
            ChartData(day: "Thu", words: 18, progress: 0.9),
            ChartData(day: "Fri", words: 12, progress: 0.6),
            ChartData(day: "Sat", words: 25, progress: 1.0),
            ChartData(day: "Sun", words: 10, progress: 0.5)
        ]
    }

    private var achievements: [Achievement] {
        [
            Achievement(id: 1, title: "First Steps", description: "Complete your first learning session", icon: "star.fill", color: .yellow, isUnlocked: true),
            Achievement(id: 2, title: "Week Warrior", description: "7-day study streak", icon: "flame.fill", color: .orange, isUnlocked: true),
            Achievement(id: 3, title: "Word Master", description: "Learn 100 words", icon: "brain.head.profile", color: .purple, isUnlocked: false),
            Achievement(id: 4, title: "Perfect Score", description: "100% accuracy in a session", icon: "target", color: .red, isUnlocked: false),
            Achievement(id: 5, title: "Speed Learner", description: "Learn 50 words in one day", icon: "bolt.fill", color: .blue, isUnlocked: false),
            Achievement(id: 6, title: "Consistent Learner", description: "30-day streak", icon: "calendar.circle.fill", color: .green, isUnlocked: false)
        ]
    }
}

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Label(trend, systemImage: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct MasteryRow: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(count) / \(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.2)
        }
    }
}

struct Achievement: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)

            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievement.isUnlocked ? achievement.color : Color(.systemGray4), lineWidth: achievement.isUnlocked ? 2 : 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

struct HabitRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct ChartData {
    let day: String
    let words: Int
    let progress: Double
}

struct WordsListView: View {
    let set: VocabularySet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddWord = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(set.words, id: \.id) { word in
                    WordRowView(word: word)
                }
                .onDelete(perform: deleteWords)
            }
            .navigationTitle(set.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWord = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView(vocabularySet: set)
            }
        }
    }

    private func deleteWords(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(set.words[index])
        }
        try? modelContext.save()
    }
}

struct WordRowView: View {
    let word: WordItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.word)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                DifficultyBadge(difficulty: word.difficulty)
            }

            if let pronunciation = word.pronunciation {
                Text(pronunciation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(word.definition)
                .font(.body)
                .lineLimit(2)

            if let example = word.example {
                Text("\"\(example)\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(difficulty.color.opacity(0.2))
            )
            .foregroundColor(difficulty.color)
    }
}

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let vocabularySet: VocabularySet?

    @State private var word = ""
    @State private var definition = ""
    @State private var pronunciation = ""
    @State private var example = ""
    @State private var selectedDifficulty: DifficultyLevel = .medium
    @State private var category = ""

    init(vocabularySet: VocabularySet? = nil) {
        self.vocabularySet = vocabularySet
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word Details") {
                    TextField("Word", text: $word)
                    TextField("Definition", text: $definition, axis: .vertical)
                        .lineLimit(3)
                    TextField("Pronunciation (optional)", text: $pronunciation)
                    TextField("Example (optional)", text: $example, axis: .vertical)
                        .lineLimit(2)
                }

                Section("Category & Difficulty") {
                    TextField("Category", text: $category)
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newWord = WordItem(
                            word: word,
                            definition: definition,
                            category: category.isEmpty ? "General" : category,
                            difficulty: selectedDifficulty
                        )

                        if let set = vocabularySet {
                            set.words.append(newWord)
                        }

                        modelContext.insert(newWord)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(word.isEmpty || definition.isEmpty)
                }
            }
        }
    }
}

#Preview {
    LearningProgressView()
        .modelContainer(for: [WordItem.self, VocabularySet.self, LearningSession.self], inMemory: true)
}