//
//  DatabaseModels.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import Foundation

// MARK: - Words Table
struct Word: Identifiable, Codable {
    let id: Int32
    let wordString: String
    let phonetic: String?
    let partsOfSpeech: String? // JSON string
    let exampleSentence: String? // JSON string (was dailySentence in code)
    let dailySubstitutes: String? // JSON string
    let usageAnalysis: String? // Example sentence usage analysis

    enum CodingKeys: String, CodingKey {
        case id = "wordId"
        case wordString
        case phonetic
        case partsOfSpeech
        case exampleSentence
        case dailySubstitutes
        case usageAnalysis
    }
}

// MARK: - Pronunciations Table
struct Pronunciation: Codable {
    let word: String // uppercase
    let arpabet: String
}

// MARK: - Users Table
struct User: Identifiable, Codable {
    let id: Int32
    let createdAt: String
    let lastLoginAt: String

    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case createdAt
        case lastLoginAt
    }
}

// MARK: - LearningPlans Table
struct LearningPlan: Codable {
    let userId: Int32
    let defaultDailyGoal: Int32
    let learningQueue: String? // JSON string
    let dailyGoalOverrides: String? // JSON string

    enum CodingKeys: String, CodingKey {
        case userId
        case defaultDailyGoal
        case learningQueue
        case dailyGoalOverrides
    }
}

// MARK: - UserWordData Table
struct UserWordData: Codable {
    let userId: Int32
    let wordId: Int32
    let masteryLevel: Int32
    let nextReviewAt: String?
    let lastReviewedAt: String?
    let incorrectCount: Int32
    let isLearned: Int32

    enum CodingKeys: String, CodingKey {
        case userId
        case wordId
        case masteryLevel
        case nextReviewAt
        case lastReviewedAt
        case incorrectCount
        case isLearned
    }
}

// MARK: - UserStats Table
struct UserStats: Codable {
    let userId: Int32
    let currentStreak: Int32
    let longestStreak: Int32
    let lastCheckinDate: String?
    let totalScore: Int32
    let totalWordsLearned: Int32

    enum CodingKeys: String, CodingKey {
        case userId
        case currentStreak
        case longestStreak
        case lastCheckinDate
        case totalScore
        case totalWordsLearned
    }
}

// MARK: - Helper Extensions
extension Word {
    func getPartsOfSpeech() -> [String: [String]]? {
        guard let data = partsOfSpeech?.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        var result: [String: [String]] = [:]
        for item in array {
            if let pos = item["pos"] as? String,
               let meanings = item["meanings"] as? [String] {
                result[pos] = meanings
            }
        }
        return result
    }

    func getDailySentence() -> String? {
        return exampleSentence
    }

    func getChineseMeaning() -> String? {
        guard let partsOfSpeechDict = getPartsOfSpeech() else { return nil }

        // 提取所有中文词义，优先显示名词和动词
        var meanings: [String] = []

        // 优先获取名词词义
        if let nounMeanings = partsOfSpeechDict["n."], !nounMeanings.isEmpty {
            meanings.append(contentsOf: nounMeanings)
        }

        // 然后获取动词词义
        if let verbMeanings = partsOfSpeechDict["v."], !verbMeanings.isEmpty {
            meanings.append(contentsOf: verbMeanings)
        }

        // 再获取形容词词义
        if let adjMeanings = partsOfSpeechDict["adj."], !adjMeanings.isEmpty {
            meanings.append(contentsOf: adjMeanings)
        }

        // 获取其他词性的词义
        for (pos, posMeanings) in partsOfSpeechDict {
            if !["n.", "v.", "adj."].contains(pos) && !posMeanings.isEmpty {
                meanings.append(contentsOf: posMeanings)
            }
        }

        // 返回第一个词义，如果没有则返回nil
        return meanings.first
    }

    func getUsageAnalysis() -> String? {
        return usageAnalysis
    }

    func getDailySubstitutes() -> [(substitute: String, scenario: String)]? {
        guard let data = dailySubstitutes?.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        return array.compactMap { item in
            if let substitute = item["substitute"] as? String,
               let scenario = item["scenario"] as? String {
                return (substitute: substitute, scenario: scenario)
            }
            return nil
        }
    }

    // MARK: - Phonetic Conversion (ARPAbet to IPA)
    /// Converts ARPAbet phonetic notation to IPA format
    func convertArpabetToIPA(_ arpabetText: String) -> String {
        let arpabetToIPAMap: [String: String] = [
            // Vowels
            "AA": "ɑ:", "AE": "æ", "AH": "ʌ", "AO": "ɔ", "AW": "aʊ",
            "AY": "aɪ", "EH": "ɛ", "ER": "ɝ", "EY": "eɪ", "IH": "ɪ",
            "IY": "i:", "OW": "oʊ", "OY": "ɔɪ", "UH": "ʊ", "UW": "u:",

            // Vowels with stress markers
            "AA1": "ˈɑ:", "AE1": "ˈæ", "AH1": "ˈʌ", "AO1": "ˈɔ", "AW1": "ˈaʊ",
            "AY1": "ˈaɪ", "EH1": "ˈɛ", "ER1": "ˈər", "EY1": "ˈeɪ", "IH1": "ˈɪ",
            "IY1": "ˈi:", "OW1": "ˈoʊ", "OY1": "ˈɔɪ", "UH1": "ˈʊ", "UW1": "ˈu:",
            "AA2": "ˌɑ:", "AE2": "ˌæ", "AH2": "ˌʌ", "AO2": "ˌɔ", "AW2": "ˌaʊ",
            "AY2": "ˌaɪ", "EH2": "ˌɛ", "ER2": "ˌər", "EY2": "ˌeɪ", "IH2": "ˌɪ",
            "IY2": "ˌi:", "OW2": "ˌoʊ", "OY2": "ˌɔɪ", "UH2": "ˌʊ", "UW2": "ˌu:",
            "AA0": "ə", "AE0": "æ", "AH0": "ə", "AO0": "ɔ", "AW0": "aʊ",
            "AY0": "aɪ", "EH0": "ɛ", "ER0": "ər", "EY0": "eɪ", "IH0": "ɪ",
            "IY0": "i:", "OW0": "oʊ", "OY0": "ɔɪ", "UH0": "ʊ", "UW0": "u:",

            // Consonants
            "B": "b", "CH": "tʃ", "D": "d", "DH": "ð", "F": "f", "G": "ɡ",
            "HH": "h", "JH": "dʒ", "K": "k", "L": "l", "M": "m", "N": "n",
            "NG": "ŋ", "P": "p", "R": "r", "S": "s", "SH": "ʃ", "T": "t",
            "TH": "θ", "V": "v", "W": "w", "Y": "j", "Z": "z", "ZH": "ʒ"
        ]

        var result = ""
        let tokens = arpabetText.components(separatedBy: .whitespaces)

        for (index, token) in tokens.enumerated() {
            // Direct lookup (handles all stress combinations)
            if let ipaSymbol = arpabetToIPAMap[token] {
                result += ipaSymbol
            } else {
                // If no mapping found, keep original
                result += token
            }

            // Add space between tokens (except last one)
            if index < tokens.count - 1 {
                result += " "
            }
        }

        return result
    }

    /// Returns the IPA-formatted phonetic transcription
    func getIPAPhonetic() -> String? {
        guard let phonetic = phonetic else { return nil }
        return convertArpabetToIPA(phonetic)
    }
}

extension LearningPlan {
    func getLearningQueue() -> [Int32]? {
        guard let data = learningQueue?.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Int32] else {
            return nil
        }
        return array
    }

    func getDailyGoalOverrides() -> [String: Int32]? {
        guard let data = dailyGoalOverrides?.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Int32] else {
            return nil
        }
        return dict
    }
}