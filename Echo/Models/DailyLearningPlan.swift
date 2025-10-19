//
//  DailyLearningPlan.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import Foundation

struct DailyLearningPlan: Identifiable, Codable {
    let id = UUID()
    let date: String // YYYY-MM-DD format
    let reviewWords: [Word] // 需要复习的单词
    let newWords: [Word] // 需要学习的新单词
    let dailyGoal: Int32 // 当天学习目标

    var totalWords: Int {
        return reviewWords.count + newWords.count
    }

    var isToday: Bool {
        return date == getCurrentDateString()
    }

    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dateString: String // YYYY-MM-DD
    let dayNumber: Int
    let isInCurrentMonth: Bool
    let hasLearningPlan: Bool
    let wordCount: Int

    var isSelected: Bool = false
}