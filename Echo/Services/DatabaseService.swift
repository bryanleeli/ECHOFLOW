//
//  DatabaseService.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import Foundation
import SQLite3
import Combine

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()

    @Published var isConnected = false
    private var db: OpaquePointer?
    private let dbPath: String

    private init() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        dbPath = fileURL.path
        openDatabase()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Connection Management
    func openDatabase() -> Bool {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            isConnected = true
            return true
        } else {
            isConnected = false
            return false
        }
    }

    func closeDatabase() {
        sqlite3_close(db)
        isConnected = false
    }

    // MARK: - Words Operations
    func getAllWords() -> [Word] {
        var words: [Word] = []

        // Use a separate database connection for thread safety
        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var localDb: OpaquePointer?

        if sqlite3_open(documentsURL.path, &localDb) == SQLITE_OK {
            let query = "SELECT * FROM Words ORDER BY RANDOM()"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(localDb, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let word = Word(
                        id: sqlite3_column_int(statement, 0),
                        wordString: String(cString: sqlite3_column_text(statement, 1)),
                        phonetic: sqlite3_column_text(statement, 2) != nil ? String(cString: sqlite3_column_text(statement, 2)) : nil,
                        partsOfSpeech: sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : nil,
                        exampleSentence: sqlite3_column_text(statement, 5) != nil ? String(cString: sqlite3_column_text(statement, 5)) : nil,
                        dailySubstitutes: sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : nil,
                        usageAnalysis: sqlite3_column_text(statement, 6) != nil ? String(cString: sqlite3_column_text(statement, 6)) : nil
                    )
                    words.append(word)
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(localDb)
        }

        return words
    }

    func getRandomWords(count: Int) -> [Word] {
        let allWords = getAllWords()
        return Array(allWords.prefix(count))
    }

    func getRandomDailySentence() -> String? {
        let query = "SELECT exampleSentence FROM Words WHERE exampleSentence IS NOT NULL ORDER BY RANDOM() LIMIT 1"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let sentenceString = sqlite3_column_text(statement, 0) != nil ? String(cString: sqlite3_column_text(statement, 0)) : nil
                sqlite3_finalize(statement)

                // Return the sentence directly (no JSON parsing needed)
                return sentenceString
            }
        }

        sqlite3_finalize(statement)
        return nil
    }

    func getCurrentUser() -> User? {
        let query = "SELECT * FROM Users LIMIT 1"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let user = User(
                    id: sqlite3_column_int(statement, 0),
                    createdAt: String(cString: sqlite3_column_text(statement, 1)),
                    lastLoginAt: String(cString: sqlite3_column_text(statement, 2))
                )
                sqlite3_finalize(statement)
                return user
            }
        }

        sqlite3_finalize(statement)
        return nil
    }

    // MARK: - Learning Plan Operations
    func getDailyLearningPlan(for date: String) -> DailyLearningPlan? {
        var reviewWords: [Word] = []
        var newWords: [Word] = []
        var dailyGoal: Int32 = 20

        // Use a separate database connection for thread safety
        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var localDb: OpaquePointer?

        if sqlite3_open(documentsURL.path, &localDb) == SQLITE_OK {
            // Get daily goal and learning queue
            let planQuery = "SELECT defaultDailyGoal, learningQueue FROM LearningPlans WHERE userId = 1"
            var planStatement: OpaquePointer?

            if sqlite3_prepare_v2(localDb, planQuery, -1, &planStatement, nil) == SQLITE_OK {
                if sqlite3_step(planStatement) == SQLITE_ROW {
                    dailyGoal = sqlite3_column_int(planStatement, 0)
                    let learningQueueJSON = sqlite3_column_text(planStatement, 1) != nil ?
                        String(cString: sqlite3_column_text(planStatement, 1)) : nil

                    // Parse learning queue to get word IDs
                    var learningQueue: [Int32] = []

                    if let queueJSON = learningQueueJSON, !queueJSON.isEmpty {
                        do {
                            let queueData = queueJSON.data(using: .utf8)

                            if let queueArray = try JSONSerialization.jsonObject(with: queueData!) as? [Int32] {
                                learningQueue = queueArray
                            } else if let queueArray = try JSONSerialization.jsonObject(with: queueData!) as? [Int] {
                                // Convert [Int] to [Int32]
                                learningQueue = queueArray.map { Int32($0) }
                            }
                        } catch {
                            // JSON parsing failed, learningQueue remains empty
                        }
                    }

                    sqlite3_finalize(planStatement)

                // Get review words (words that need review on or before this date)
                let reviewQuery = """
                SELECT w.* FROM Words w
                INNER JOIN UserWordData uwd ON w.wordId = uwd.wordId
                WHERE uwd.userId = 1 AND uwd.nextReviewAt <= ?
                ORDER BY uwd.nextReviewAt ASC
                """
                var reviewStatement: OpaquePointer?

                if sqlite3_prepare_v2(localDb, reviewQuery, -1, &reviewStatement, nil) == SQLITE_OK {
                    sqlite3_bind_text(reviewStatement, 1, date, -1, nil)

                    while sqlite3_step(reviewStatement) == SQLITE_ROW {
                        let word = Word(
                            id: sqlite3_column_int(reviewStatement, 0),
                            wordString: String(cString: sqlite3_column_text(reviewStatement, 1)),
                            phonetic: sqlite3_column_text(reviewStatement, 2) != nil ? String(cString: sqlite3_column_text(reviewStatement, 2)) : nil,
                            partsOfSpeech: sqlite3_column_text(reviewStatement, 3) != nil ? String(cString: sqlite3_column_text(reviewStatement, 3)) : nil,
                            exampleSentence: sqlite3_column_text(reviewStatement, 4) != nil ? String(cString: sqlite3_column_text(reviewStatement, 4)) : nil,
                            dailySubstitutes: sqlite3_column_text(reviewStatement, 5) != nil ? String(cString: sqlite3_column_text(reviewStatement, 5)) : nil,
                            usageAnalysis: sqlite3_column_text(reviewStatement, 6) != nil ? String(cString: sqlite3_column_text(reviewStatement, 6)) : nil
                        )
                        reviewWords.append(word)
                    }
                }
                sqlite3_finalize(reviewStatement)

                // Get new words (from learning queue, excluding already learned words)
                let newWordsCount = max(0, dailyGoal - Int32(reviewWords.count))
                if newWordsCount > 0 && !learningQueue.isEmpty {
                    // Get words from learning queue that are not already learned
                    let newWordsQuery = """
                    SELECT w.* FROM Words w
                    WHERE w.wordId IN (\(learningQueue.prefix(Int(newWordsCount)).map { String($0) }.joined(separator: ",")))
                    AND NOT EXISTS (
                        SELECT 1 FROM UserWordData uwd
                        WHERE uwd.userId = 1 AND uwd.wordId = w.wordId
                    )
                    """
                    var newWordsStatement: OpaquePointer?

                    
                    if sqlite3_prepare_v2(db, newWordsQuery, -1, &newWordsStatement, nil) == SQLITE_OK {
                        while sqlite3_step(newWordsStatement) == SQLITE_ROW {
                            let word = Word(
                                id: sqlite3_column_int(newWordsStatement, 0),
                                wordString: String(cString: sqlite3_column_text(newWordsStatement, 1)),
                                phonetic: sqlite3_column_text(newWordsStatement, 2) != nil ? String(cString: sqlite3_column_text(newWordsStatement, 2)) : nil,
                                partsOfSpeech: sqlite3_column_text(newWordsStatement, 3) != nil ? String(cString: sqlite3_column_text(newWordsStatement, 3)) : nil,
                                exampleSentence: sqlite3_column_text(newWordsStatement, 4) != nil ? String(cString: sqlite3_column_text(newWordsStatement, 4)) : nil,
                                dailySubstitutes: sqlite3_column_text(newWordsStatement, 5) != nil ? String(cString: sqlite3_column_text(newWordsStatement, 5)) : nil,
                                usageAnalysis: sqlite3_column_text(newWordsStatement, 6) != nil ? String(cString: sqlite3_column_text(newWordsStatement, 6)) : nil
                            )
                            newWords.append(word)
                        }
                    }
                    sqlite3_finalize(newWordsStatement)
                }
            }
        }
            sqlite3_close(localDb)
        } else {
            sqlite3_close(localDb)
        }

        return DailyLearningPlan(
            date: date,
            reviewWords: reviewWords,
            newWords: newWords,
            dailyGoal: dailyGoal
        )
    }

    func getLearningPlanCount(for date: String) -> Int {
        guard let plan = getDailyLearningPlan(for: date) else {
            return 0
        }
        return plan.totalWords
    }

    func getCalendarDays(for month: Date) -> [CalendarDay] {
        var calendarDays: [CalendarDay] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Get first day of month and number of days
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!

        // Get first weekday (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Add days from previous month to fill first week
        let daysFromPreviousMonth = firstWeekday - 1
        for i in (1...daysFromPreviousMonth).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth)!
            let dateString = formatter.string(from: date)
            let dayNumber = calendar.component(.day, from: date)

            calendarDays.append(CalendarDay(
                date: date,
                dateString: dateString,
                dayNumber: dayNumber,
                isInCurrentMonth: false,
                hasLearningPlan: false,
                wordCount: 0
            ))
        }

        // Add days of current month
        var currentDate = firstDayOfMonth
        let today = calendar.startOfDay(for: Date())
        while currentDate <= lastDayOfMonth {
            let dateString = formatter.string(from: currentDate)
            let dayNumber = calendar.component(.day, from: currentDate)

            // Only generate learning plans for today and future dates
            if currentDate >= today {
                let wordCount = getLearningPlanCount(for: dateString)
                calendarDays.append(CalendarDay(
                    date: currentDate,
                    dateString: dateString,
                    dayNumber: dayNumber,
                    isInCurrentMonth: true,
                    hasLearningPlan: wordCount > 0,
                    wordCount: wordCount
                ))
            } else {
                // Past dates don't have learning plans
                calendarDays.append(CalendarDay(
                    date: currentDate,
                    dateString: dateString,
                    dayNumber: dayNumber,
                    isInCurrentMonth: true,
                    hasLearningPlan: false,
                    wordCount: 0
                ))
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Add days from next month to complete last week
        let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
        let daysFromNextMonth = 7 - lastWeekday

        for i in 1...daysFromNextMonth {
            let date = calendar.date(byAdding: .day, value: i, to: lastDayOfMonth)!
            let dateString = formatter.string(from: date)
            let dayNumber = calendar.component(.day, from: date)

            calendarDays.append(CalendarDay(
                date: date,
                dateString: dateString,
                dayNumber: dayNumber,
                isInCurrentMonth: false,
                hasLearningPlan: false,
                wordCount: 0
            ))
        }

        return calendarDays
    }

    // MARK: - Debug Methods
    func debugDatabaseState() {
        // Debug method - currently disabled
    }

    func testLearningPlanGeneration() {
        // Debug method - currently disabled
    }

    private func checkLearningQueueDirectly() {
        // Debug method - currently disabled
    }

    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}