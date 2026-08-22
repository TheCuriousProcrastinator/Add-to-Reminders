//
//  ContentView.swift
//  QuickAdd
//
//  Created by Alex on 8/22/26.
//

import EventKit
import SwiftUI

struct ContentView: View {
    private let onSubmit: () -> Void
    private let onEscape: () -> Void
    private let lastUsedListKey = "lastUsedReminderListIdentifier"

    @State private var title = ""
    @State private var selectedListID = ""
    @State private var lists: [EKCalendar] = []
    @State private var errorMessage: String?
    @State private var isLoadingLists = false
    @State private var isSaving = false
    @State private var eventStore = EKEventStore()
    @FocusState private var titleFieldFocused: Bool

    init(onSubmit: @escaping () -> Void = {}, onEscape: @escaping () -> Void = {}) {
        self.onSubmit = onSubmit
        self.onEscape = onEscape
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Add")
                .font(.headline)

            TextField("Reminder title", text: $title)
                .textFieldStyle(.roundedBorder)
                .focused($titleFieldFocused)
                .onSubmit {
                    submitTitle()
                }

            Picker("List", selection: $selectedListID) {
                if lists.isEmpty {
                    Text(isLoadingLists ? "Loading…" : "No lists available")
                        .tag("")
                } else {
                    ForEach(lists, id: \.calendarIdentifier) { list in
                        Text(list.title).tag(list.calendarIdentifier)
                    }
                }
            }
            .pickerStyle(.menu)
            .disabled(lists.isEmpty || isSaving)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Text(isSaving ? "Saving…" : "Return to save  •  Esc to cancel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(width: 520)
        .onReceive(NotificationCenter.default.publisher(for: .quickAddTitleFocusRequested)) { _ in
            titleFieldFocused = true
        }
        .onExitCommand(perform: onEscape)
        .onChange(of: selectedListID) { _, listID in
            guard !listID.isEmpty else { return }
            UserDefaults.standard.set(listID, forKey: lastUsedListKey)
        }
        .task {
            loadLists()
        }
    }

    private func loadLists() {
        errorMessage = nil
        isLoadingLists = true

        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess:
            finishLoadingLists()

        case .notDetermined:
            eventStore.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        finishLoadingLists()
                    } else {
                        isLoadingLists = false
                        errorMessage = error?.localizedDescription
                            ?? "Reminders access was denied."
                    }
                }
            }

        default:
            isLoadingLists = false
            errorMessage = "Reminders access was denied. Allow it in System Settings."
        }
    }

    private func finishLoadingLists() {
        lists = eventStore.calendars(for: .reminder).sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        isLoadingLists = false

        guard !lists.isEmpty else {
            errorMessage = "No Reminders lists are available."
            return
        }

        let lastUsedListID = UserDefaults.standard.string(forKey: lastUsedListKey)
        let defaultListID = eventStore.defaultCalendarForNewReminders()?.calendarIdentifier
        selectedListID = [lastUsedListID, defaultListID]
            .compactMap { $0 }
            .first { listID in lists.contains { $0.calendarIdentifier == listID } }
            ?? lists[0].calendarIdentifier
    }

    private func submitTitle() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !isSaving else { return }
        guard let list = lists.first(where: { $0.calendarIdentifier == selectedListID }) else {
            errorMessage = "Choose a Reminders list before saving."
            return
        }

        isSaving = true
        errorMessage = nil

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = trimmedTitle
        reminder.calendar = list

        do {
            try eventStore.save(reminder, commit: true)
            title = ""
            onSubmit()
        } catch {
            isSaving = false
            errorMessage = "Could not save reminder: \(error.localizedDescription)"
        }
    }
}

extension Notification.Name {
    static let quickAddTitleFocusRequested = Notification.Name("quickAddTitleFocusRequested")
}

#Preview {
    ContentView()
}
