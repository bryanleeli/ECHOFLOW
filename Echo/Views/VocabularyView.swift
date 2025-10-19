//
//  VocabularyView.swift
//  WordSpark
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI
import SwiftData

struct VocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vocabularySets: [VocabularySet]
    @State private var showingAddSet = false
    @State private var searchText = ""
    @State private var selectedSet: VocabularySet?

    var filteredSets: [VocabularySet] {
        if searchText.isEmpty {
            return vocabularySets
        } else {
            return vocabularySets.filter { set in
                set.name.localizedCaseInsensitiveContains(searchText) ||
                set.setDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)

                if filteredSets.isEmpty {
                    EmptyStateView(
                        systemImage: "folder",
                        title: "No Vocabulary Sets",
                        subtitle: searchText.isEmpty ?
                            "Create your first vocabulary set to get started" :
                            "No sets found matching \"\(searchText)\""
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredSets, id: \.id) { set in
                                VocabularySetDetailView(set: set)
                                    .onTapGesture {
                                        selectedSet = set
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Vocabulary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSet) {
                AddVocabularySetView()
            }
            .sheet(item: $selectedSet) { set in
                VocabularySetDetailView(set: set)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search vocabulary sets...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

struct VocabularySetDetailView: View {
    let set: VocabularySet
    @Environment(\.modelContext) private var modelContext
    @State private var showingWords = false
    @State private var showingEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: set.icon)
                    .font(.title2)
                    .foregroundColor(Color(set.color))

                Spacer()

                Menu {
                    Button(action: { showingEdit = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: deleteSet) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }

            Text(set.name)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)

            if let description = set.setDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            HStack {
                Label("\(set.words.count)", systemImage: "book.fill")
                Spacer()
                Label(formatDate(set.createdAt), systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Button(action: { showingWords = true }) {
                HStack {
                    Text("View Words")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingWords) {
            WordsListView(set: set)
        }
        .sheet(isPresented: $showingEdit) {
            EditVocabularySetView(set: set)
        }
    }

    private func deleteSet() {
        modelContext.delete(set)
        try? modelContext.save()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct AddVocabularySetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var setDescription = ""
    @State private var selectedIcon = "book.fill"
    @State private var selectedColor = "blue"

    let icons = ["book.fill", "graduationcap.fill", "star.fill", "heart.fill", "briefcase.fill"]
    let colors = ["blue", "green", "red", "orange", "purple"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $setDescription, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color.blue : Color(.systemGray5))
                                    )
                            }
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Vocabulary Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newSet = VocabularySet(
                            name: name,
                            description: setDescription.isEmpty ? nil : setDescription,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        modelContext.insert(newSet)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditVocabularySetView: View {
    let set: VocabularySet
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var setDescription: String
    @State private var selectedIcon: String
    @State private var selectedColor: String

    init(set: VocabularySet) {
        self.set = set
        _name = State(initialValue: set.name)
        _setDescription = State(initialValue: set.setDescription ?? "")
        _selectedIcon = State(initialValue: set.icon)
        _selectedColor = State(initialValue: set.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $setDescription, axis: .vertical)
                        .lineLimit(3)
                }
                // 图标和颜色选择部分 (与AddVocabularySetView相同)
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        set.name = name
                        set.setDescription = setDescription.isEmpty ? nil : setDescription
                        set.icon = selectedIcon
                        set.color = selectedColor
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    VocabularyView()
        .modelContainer(for: [VocabularySet.self, WordItem.self], inMemory: true)
}