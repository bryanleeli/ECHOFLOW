//
//  WordItem.swift
//  WordSpark
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI
import SwiftData

@Model
final class WordItem {
    var id: UUID
    var word: String
    var definition: String
    var pronunciation: String?
    var example: String?
    var isLearned: Bool
    var difficulty: DifficultyLevel
    var category: String
    var createdAt: Date
    var lastReviewed: Date?
    var reviewCount: Int

    init(word: String, definition: String, category: String, difficulty: DifficultyLevel = .medium) {
        self.id = UUID()
        self.word = word
        self.definition = definition
        self.category = category
        self.difficulty = difficulty
        self.isLearned = false
        self.createdAt = Date()
        self.reviewCount = 0
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

@Model
final class VocabularySet {
    var id: UUID
    var name: String
    var setDescription: String?
    var icon: String
    var color: String
    var createdAt: Date
    var words: [WordItem]

    init(name: String, description: String? = nil, icon: String = "book.fill", color: String = "blue") {
        self.id = UUID()
        self.name = name
        self.setDescription = description
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.words = []
    }
}

@Model
final class LearningSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var wordsStudied: Int
    var correctAnswers: Int
    var totalTime: Int

    init() {
        self.id = UUID()
        self.startTime = Date()
        self.wordsStudied = 0
        self.correctAnswers = 0
        self.totalTime = 0
    }

    func endSession() {
        self.endTime = Date()
        if let endTime = endTime {
            self.totalTime = Int(endTime.timeIntervalSince(startTime))
        }
    }
}