//
//  ProfileView.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var selectedMonth = Date()
    @State private var calendarDays: [CalendarDay] = []
    @State private var selectedDate: CalendarDay?
    @State private var dailyLearningPlan: DailyLearningPlan?
    @State private var showingLearningPlan = false
    @State private var practiceHistory: [PracticeRecord] = [
        PracticeRecord(date: "October 20, 2024", type: "Challenged Sentences", accuracy: 100),
        PracticeRecord(date: "October 19, 2024", type: "Challenged Sentences", accuracy: 90),
        PracticeRecord(date: "October 18, 2024", type: "Challenged Sentences", accuracy: 80)
    ]

    private let databaseService = DatabaseService.shared
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // 用户信息区域
                    userInfoSection

                    // 学习连续日历
                    streakCalendarSection

                    // 练习历史
                    practiceHistorySection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            .background(Color(red: 0.102, green: 0.114, blue: 0.180)) // #1a1d2e
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showingLearningPlan) {
            if let plan = dailyLearningPlan, let selectedDay = selectedDate {
                LearningPlanDetailView(plan: plan, date: selectedDay)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()

            Text("Profile")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .tracking(0.07)

            Button(action: {
                // 设置按钮
            }) {
                Image(systemName: "gearshape")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 72)
    }

    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // 头像
            AsyncImage(url: URL(string: "http://localhost:3845/assets/a535d398211216823484617b50152c878275fe1f.png")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 128, height: 128)
            }
            .frame(width: 128, height: 128)
            .clipShape(Circle())

            // 用户信息
            VStack(spacing: 4) {
                Text("Sophia Li")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .tracking(-0.45)

                Text("Level 5")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
                    .tracking(-0.3125)

                Text("1200 XP")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
                    .tracking(-0.3125)
            }
        }
        .padding(.top, 32)
    }

    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tracking(-0.3125)

            VStack(spacing: 24) {
                // 月份选择器
                monthSelector

                // 日历网格
                calendarGrid
            }
            .padding(24)
            .background(Color(red: 0.145, green: 0.157, blue: 0.224)) // #252839
            .cornerRadius(16)
        }
    }

    private var monthSelector: some View {
        HStack {
            Button(action: {
                selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                loadCalendarDays()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            Text(monthFormatter.string(from: selectedMonth))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tracking(-0.3125)

            Spacer()

            Button(action: {
                selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                loadCalendarDays()
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // 星期标题
            HStack(spacing: 12) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.416, green: 0.447, blue: 0.51)) // #6a7282
                        .frame(maxWidth: .infinity)
                }
            }

            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.id) { calendarDay in
                    InteractiveCalendarDayView(
                        calendarDay: calendarDay,
                        isSelected: selectedDate?.id == calendarDay.id
                    ) {
                        selectCalendarDay(calendarDay)
                    }
                }
            }
        }
        .onAppear {
            loadCalendarDays()
        }
    }

    private var practiceHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice History")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .tracking(-0.44)

            VStack(spacing: 12) {
                ForEach(practiceHistory, id: \.id) { record in
                    PracticeHistoryRow(record: record)
                }
            }
        }
    }

    
    // MARK: - Helper Methods
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private func loadCalendarDays() {
        calendarDays = databaseService.getCalendarDays(for: selectedMonth)
    }

    private func selectCalendarDay(_ calendarDay: CalendarDay) {
        selectedDate = calendarDay

        // Load learning plan for selected date
        Task {
            dailyLearningPlan = databaseService.getDailyLearningPlan(for: calendarDay.dateString)
            showingLearningPlan = true
        }
    }
}

struct InteractiveCalendarDayView: View {
    let calendarDay: CalendarDay
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendarDay.dayNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(calendarDay.isInCurrentMonth ? .white : Color.white.opacity(0.4))

                // 显示学习计划指示器
                if calendarDay.hasLearningPlan {
                    VStack(spacing: 2) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)

                        Text("\(calendarDay.wordCount)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.orange)
                    }
                } else {
                    Spacer()
                        .frame(height: 12)
                }
            }
            .frame(width: 32, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.357, green: 0.435, blue: 0.847) : Color.clear)
            )
        }
        .disabled(!calendarDay.isInCurrentMonth && !calendarDay.hasLearningPlan)
    }
}

struct LearningPlanDetailView: View {
    let plan: DailyLearningPlan
    let date: CalendarDay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // 统计信息
                        statsSection

                        // 复习单词
                        if !plan.reviewWords.isEmpty {
                            reviewWordsSection
                        }

                        // 新单词
                        if !plan.newWords.isEmpty {
                            newWordsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .background(Color(red: 0.102, green: 0.122, blue: 0.180)) // #1a1f2e
            .navigationTitle("Learning Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(dateFormatter.string(from: date.date))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)

            if plan.isToday {
                Text("Today's Learning Plan")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(plan.totalWords)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)

                Text("Total Words")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
            }

            Divider()
                .background(Color(red: 0.6, green: 0.63, blue: 0.69))

            VStack(spacing: 4) {
                Text("\(plan.reviewWords.count)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 0, green: 0.827, blue: 0.949)) // #00d3f2

                Text("Review")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
            }

            Divider()
                .background(Color(red: 0.6, green: 0.63, blue: 0.69))

            VStack(spacing: 4) {
                Text("\(plan.newWords.count)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 0.369, green: 0.769, blue: 0.875)) // #5ec4e0

                Text("New")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
            }
        }
        .padding(16)
        .background(Color(red: 0.176, green: 0.208, blue: 0.282)) // #2d3548
        .cornerRadius(12)
    }

    private var reviewWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Words (\(plan.reviewWords.count))")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(plan.reviewWords, id: \.id) { word in
                    WordCardView(word: word, type: .review)
                }
            }
        }
    }

    private var newWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Words (\(plan.newWords.count))")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(plan.newWords, id: \.id) { word in
                    WordCardView(word: word, type: .new)
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }
}

struct WordCardView: View {
    let word: Word
    let type: WordType

    enum WordType {
        case review
        case new
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.wordString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Circle()
                    .fill(type == .review ? Color(red: 0, green: 0.827, blue: 0.949) : Color(red: 0.369, green: 0.769, blue: 0.875))
                    .frame(width: 8, height: 8)
            }

            
            // 显示第一个释义
            if let partsOfSpeech = word.getPartsOfSpeech(),
               let firstMeanings = partsOfSpeech.values.first,
               let firstDefinition = firstMeanings.first {
                Text(firstDefinition)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.82, green: 0.835, blue: 0.863))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(red: 0.145, green: 0.157, blue: 0.224)) // #252839
        .cornerRadius(8)
    }
}

// Legacy CalendarDayView (keeping for compatibility)
struct CalendarDayView: View {
    let day: Int
    let isActive: Bool

    var body: some View {
        Text("\(day)")
            .font(.system(size: 16))
            .foregroundColor(isActive ? .white : Color(red: 0.82, green: 0.835, blue: 0.863)) // #d1d5dc
            .frame(width: 40, height: 40)
            .background(isActive ? Color(red: 0.357, green: 0.435, blue: 0.847) : Color.clear)
            .cornerRadius(20)
    }
}

struct PracticeRecord: Identifiable {
    let id = UUID()
    let date: String
    let type: String
    let accuracy: Int
}

struct PracticeHistoryRow: View {
    let record: PracticeRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .tracking(-0.3125)

                Text(record.type)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
                    .tracking(-0.3125)
            }

            Spacer()

            Text("\(record.accuracy)%")
                .font(.system(size: 16))
                .foregroundColor(record.accuracy == 100 ? Color(red: 0.357, green: 0.435, blue: 0.847) : Color(red: 0.82, green: 0.835, blue: 0.863))
                .tracking(-0.3125)
        }
        .padding(16)
        .background(Color(red: 0.145, green: 0.157, blue: 0.224)) // #252839
        .cornerRadius(14)
    }
}

#Preview {
    ProfileView()
}