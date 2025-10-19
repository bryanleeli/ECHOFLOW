//
//  UserInitializationService.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import Foundation
import SQLite3
import Combine

@MainActor
class UserInitializationService: ObservableObject {
    static let shared = UserInitializationService()

    @Published var isInitialized = false
    @Published var initializationProgress: String = ""
    @Published var currentUser: User?

    private init() {}

    // MARK: - User Initialization Flow
    func initializeUser() async -> Bool {
        initializationProgress = "Initializing user..."

        // Step 1: Copy pre-built database if needed
        let databaseCopied = await copyPrebuiltDatabaseIfNeeded()
        if !databaseCopied {
            return false
        }

        // Step 2: Load user profile and initial stats
        let profileLoaded = await loadUserProfile()
        if !profileLoaded {
            return false
        }

        // Step 3: Load default learning plan
        let planLoaded = await loadLearningPlan()
        if !planLoaded {
            return false
        }

        isInitialized = true
        initializationProgress = "User initialization complete!"

        return true
    }

    // MARK: - Private Methods
    private func copyPrebuiltDatabaseIfNeeded() async -> Bool {
        initializationProgress = "Setting up database..."

        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        // Check if database already exists and is valid
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: documentsURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    if fileSize > 0 {
                        // Additional validation: try to open the database briefly to verify it's valid
                        var testDb: OpaquePointer?
                        let result = sqlite3_open_v2(documentsURL.path, &testDb, SQLITE_OPEN_READONLY, nil)
                        if result == SQLITE_OK {
                            sqlite3_close(testDb)
                            return true
                        } else {
                            sqlite3_close(testDb)
                            // Close any existing connections and remove corrupted file
                            try? FileManager.default.removeItem(atPath: documentsURL.path)
                        }
                    } else {
                        // Remove the empty file and continue with copy process
                        try FileManager.default.removeItem(atPath: documentsURL.path)
                    }
                }
            } catch {
                // Remove potentially corrupted file
                try? FileManager.default.removeItem(atPath: documentsURL.path)
            }
        }

        // Copy pre-built database from bundle resources
        guard let bundleDBPath = Bundle.main.path(forResource: "echoinit", ofType: "db") else {
            let resources = Bundle.main.paths(forResourcesOfType: nil, inDirectory: nil)
            for resource in resources.prefix(10) {
            }
            return false
        }

        do {
            try FileManager.default.copyItem(atPath: bundleDBPath, toPath: documentsURL.path)
            return true
        } catch {
            return false
        }
    }

    private func loadUserProfile() async -> Bool {
        initializationProgress = "Loading user profile..."

        // Connect to database and load user profile
        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var db: OpaquePointer?

        if sqlite3_open(documentsURL.path, &db) == SQLITE_OK {
            // Check if user with userId=1 exists
            let query = "SELECT userId, createdAt, lastLoginAt FROM Users WHERE userId = 1"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    let userId = sqlite3_column_int(statement, 0)

                    // Safely extract text columns with nil checking
                    let createdAtCString = sqlite3_column_text(statement, 1)
                    let createdAt = createdAtCString != nil ? String(cString: createdAtCString!) : ""

                    let lastLoginAtCString = sqlite3_column_text(statement, 2)
                    let lastLoginAt = lastLoginAtCString != nil ? String(cString: lastLoginAtCString!) : ""

                    sqlite3_finalize(statement)
                    sqlite3_close(db)
                    return true
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }

        return false
    }

    private func loadLearningPlan() async -> Bool {
        initializationProgress = "Loading learning plan..."

        // Connect to database and load learning plan
        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")


        var db: OpaquePointer?

        if sqlite3_open(documentsURL.path, &db) == SQLITE_OK {

            // Check if LearningPlans table exists
            let checkTableQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name='LearningPlans'"
            var checkStatement: OpaquePointer?

            if sqlite3_prepare_v2(db, checkTableQuery, -1, &checkStatement, nil) == SQLITE_OK {
                if sqlite3_step(checkStatement) == SQLITE_ROW {
                    let tableName = String(cString: sqlite3_column_text(checkStatement, 0))
                } else {
                }
            }
            sqlite3_finalize(checkStatement)

            // Check record count in LearningPlans table
            let countQuery = "SELECT COUNT(*) as count FROM LearningPlans"
            var countStatement: OpaquePointer?

            if sqlite3_prepare_v2(db, countQuery, -1, &countStatement, nil) == SQLITE_OK {
                if sqlite3_step(countStatement) == SQLITE_ROW {
                    let count = sqlite3_column_int(countStatement, 0)
                }
            }
            sqlite3_finalize(countStatement)

            // Try to load learning plan for userId=1
            let query = "SELECT defaultDailyGoal, learningQueue FROM LearningPlans WHERE userId = 1"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {

                if sqlite3_step(statement) == SQLITE_ROW {
                    let defaultDailyGoal = sqlite3_column_int(statement, 0)
                    let learningQueueJSON = sqlite3_column_text(statement, 1) != nil ?
                        String(cString: sqlite3_column_text(statement, 1)) : nil

                    sqlite3_finalize(statement)
                    sqlite3_close(db)
                    return true
                } else {
                    sqlite3_finalize(statement)
                    sqlite3_close(db)
                    return await initializeLearningPlan()
                }
            } else {
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        } else {
        }

        return false
    }

    private func initializeLearningPlan() async -> Bool {
        initializationProgress = "Creating initial learning plan..."

        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var db: OpaquePointer?

        if sqlite3_open(documentsURL.path, &db) == SQLITE_OK {

            // Check Words table first
            let wordsCountQuery = "SELECT COUNT(*) as count FROM Words"
            var wordsCountStatement: OpaquePointer?

            if sqlite3_prepare_v2(db, wordsCountQuery, -1, &wordsCountStatement, nil) == SQLITE_OK {
                if sqlite3_step(wordsCountStatement) == SQLITE_ROW {
                    let wordCount = sqlite3_column_int(wordsCountStatement, 0)
                }
            }
            sqlite3_finalize(wordsCountStatement)

            // Get all word IDs from Words table
            let wordQuery = "SELECT wordId FROM Words ORDER BY RANDOM()"
            var wordStatement: OpaquePointer?
            var wordIds: [Int32] = []


            if sqlite3_prepare_v2(db, wordQuery, -1, &wordStatement, nil) == SQLITE_OK {
                while sqlite3_step(wordStatement) == SQLITE_ROW {
                    let wordId = sqlite3_column_int(wordStatement, 0)
                    wordIds.append(wordId)
                }
            } else {
            }
            sqlite3_finalize(wordStatement)

            if !wordIds.isEmpty {
                // Create JSON array for learning queue
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: wordIds)
                    let learningQueueJSON = String(data: jsonData, encoding: .utf8)

                    // Insert initial learning plan
                    let insertQuery = """
                    INSERT OR REPLACE INTO LearningPlans (userId, defaultDailyGoal, learningQueue)
                    VALUES (1, 20, ?)
                    """
                    var insertStatement: OpaquePointer?

                    if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) == SQLITE_OK {
                        if let queueJSON = learningQueueJSON {
                            sqlite3_bind_text(insertStatement, 1, queueJSON, -1, nil)
                        } else {
                            sqlite3_finalize(insertStatement)
                            sqlite3_close(db)
                            return false
                        }

                        let result = sqlite3_step(insertStatement)
                        sqlite3_finalize(insertStatement)

                        if result == SQLITE_DONE {

                            // Show first few words in queue for verification
                            if !wordIds.isEmpty {

                                // Get sample words from database to show actual word content
                                if let sampleWords = getSampleWordsFromDatabase(wordIds: Array(wordIds.prefix(5))) {
                                    for (index, word) in sampleWords.enumerated() {
                                    }
                                }
                            }

                            // Verify the data was actually written
                            let verifyQuery = "SELECT learningQueue FROM LearningPlans WHERE userId = 1"
                            var verifyStatement: OpaquePointer?
                            if sqlite3_prepare_v2(db, verifyQuery, -1, &verifyStatement, nil) == SQLITE_OK {
                                if sqlite3_step(verifyStatement) == SQLITE_ROW {
                                    let storedQueue = sqlite3_column_text(verifyStatement, 0) != nil ?
                                        String(cString: sqlite3_column_text(verifyStatement, 0)) : "NULL"

                                    if !storedQueue.isEmpty && storedQueue != "NULL" {
                                        sqlite3_finalize(verifyStatement)
                                        sqlite3_close(db)
                                        return true
                                    } else {
                                    }
                                }
                            }
                            sqlite3_finalize(verifyStatement)
                            sqlite3_close(db)
                            return false
                        }
                    }
                    sqlite3_finalize(insertStatement)
                } catch {
                }
            }
            sqlite3_close(db)
        }

        return false
    }

    // MARK: - Helper Methods
    func updateLastLogin() async -> Bool {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var db: OpaquePointer?

        if sqlite3_open(documentsURL.path, &db) == SQLITE_OK {
            let query = "UPDATE Users SET lastLoginAt = ? WHERE userId = 1"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, timestamp, -1, nil)
                let result = sqlite3_step(statement)
                sqlite3_finalize(statement)
                sqlite3_close(db)

                if result == SQLITE_DONE {
                    return true
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }

        return false
    }

    // MARK: - Debug Helper Methods
    private func getSampleWordsFromDatabase(wordIds: [Int32]) -> [Word]? {
        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var db: OpaquePointer?
        var words: [Word] = []

        if sqlite3_open(documentsURL.path, &db) == SQLITE_OK {
            let idList = wordIds.map { String($0) }.joined(separator: ",")
            let query = "SELECT * FROM Words WHERE wordId IN (\(idList))"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let word = Word(
                        id: sqlite3_column_int(statement, 0),
                        wordString: String(cString: sqlite3_column_text(statement, 1)),
                        phonetic: sqlite3_column_text(statement, 2) != nil ? String(cString: sqlite3_column_text(statement, 2)) : nil,
                        partsOfSpeech: sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : nil,
                        exampleSentence: sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : nil,
                        dailySubstitutes: sqlite3_column_text(statement, 5) != nil ? String(cString: sqlite3_column_text(statement, 5)) : nil,
                        usageAnalysis: sqlite3_column_text(statement, 6) != nil ? String(cString: sqlite3_column_text(statement, 6)) : nil
                    )
                    words.append(word)
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }

        return words.isEmpty ? nil : words
    }

    func debugCurrentLearningPlan() async {

        let documentsURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("echo.db")

        var db: OpaquePointer?

        if sqlite3_open(documentsURL.path, &db) == SQLITE_OK {
            // Check if learning plan exists
            let query = "SELECT defaultDailyGoal, learningQueue FROM LearningPlans WHERE userId = 1"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    let dailyGoal = sqlite3_column_int(statement, 0)
                    let queueJSON = sqlite3_column_text(statement, 1) != nil ?
                        String(cString: sqlite3_column_text(statement, 1)) : nil


                    // Parse and verify queue
                    if let queueJSON = queueJSON,
                       let queueData = queueJSON.data(using: .utf8),
                       let queueArray = try? JSONSerialization.jsonObject(with: queueData) as? [Int32] {

                        // Show sample words
                        if let sampleWords = getSampleWordsFromDatabase(wordIds: Array(queueArray.prefix(3))) {
                            for word in sampleWords {
                            }
                        }
                    } else {
                    }
                } else {
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }

    }
}