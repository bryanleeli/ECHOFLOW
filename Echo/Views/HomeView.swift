//
//  HomeView.swift
//  WordSpark
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vocabularySets: [VocabularySet]
    @Query private var learningSessions: [LearningSession]

    @State private var showingAddWord = false
    @State private var todayWord: WordItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 欢迎头部
                    welcomeHeader

                    // 今日单词卡片
                    todayWordCard

                    // 学习统计
                    statisticsSection

                    // 快速操作
                    quickActionsSection

                    // 最近词汇集
                    recentVocabularySets
                }
                .padding()
            }
            .navigationTitle("WordSpark")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWord = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
        }
        .onAppear {
            loadTodayWord()
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Let's learn something new today")
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayWordCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                Text("Word of the Day")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let word = todayWord {
                VStack(alignment: .leading, spacing: 12) {
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
                        .lineLimit(3)

                    if let example = word.example {
                        Text("\"\(example)\"")
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No word for today")
                        .font(.headline)
                    Text("Add some words to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Words Learned",
                    value: "\(totalWordsLearned)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Study Streak",
                    value: "\(studyStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Total Words",
                    value: "\(totalWords)",
                    icon: "book.fill",
                    color: .blue
                )

                StatCard(
                    title: "Accuracy",
                    value: "\(accuracy)%",
                    icon: "target",
                    color: .purple
                )
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Start Learning",
                    icon: "play.circle.fill",
                    color: .blue
                ) {
                    // 导航到学习页面
                }

                QuickActionCard(
                    title: "Practice",
                    icon: "pencil.and.outline",
                    color: .green
                ) {
                    // 开始练习
                }

                QuickActionCard(
                    title: "Review",
                    icon: "arrow.clockwise",
                    color: .orange
                ) {
                    // 复习模式
                }

                QuickActionCard(
                    title: "Quiz",
                    icon: "questionmark.circle.fill",
                    color: .purple
                ) {
                    // 测验模式
                }
            }
        }
    }

    private var recentVocabularySets: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Vocabulary Sets")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("See All") {
                    // 查看所有词汇集
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if vocabularySets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No vocabulary sets yet")
                        .font(.headline)
                    Text("Create your first vocabulary set to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(vocabularySets.prefix(4), id: \.id) { set in
                        VocabularySetCard(set: set)
                    }
                }
            }
        }
    }

    private var totalWordsLearned: Int {
        // 计算已学习的单词数量
        0 // 实际实现需要从数据模型计算
    }

    private var studyStreak: Int {
        // 计算连续学习天数
        0 // 实际实现需要根据学习记录计算
    }

    private var totalWords: Int {
        // 计算总单词数量
        0 // 实际实现需要从数据模型计算
    }

    private var accuracy: Int {
        // 计算学习准确率
        85 // 示例值
    }

    private func loadTodayWord() {
        // 加载今日单词的逻辑
        // 这里应该从数据模型中随机选择一个单词
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
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
                .fill(Color(.systemGray6))
        )
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VocabularySetCard: View {
    let set: VocabularySet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: set.icon)
                    .foregroundColor(.blue)
                Spacer()
                Text("\(set.words.count) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(set.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)

            if let description = set.setDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [WordItem.self, VocabularySet.self, LearningSession.self], inMemory: true)
}