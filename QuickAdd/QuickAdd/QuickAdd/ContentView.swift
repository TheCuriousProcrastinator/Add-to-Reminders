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
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var hasDueTime = false
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
        ZStack(alignment: .top) {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))

                    Text("Add to Reminders")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)

                VStack(alignment: .leading, spacing: 7) {
                    TextField("Reminder title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .medium))
                        .focused($titleFieldFocused)
                        .onSubmit {
                            submitTitle()
                        }
                        .padding(.horizontal, 15)
                        .padding(.top, 11)

                    HStack(spacing: 7) {
                        dateControl

                        if hasDueDate {
                            timeControl
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 11)
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .padding(.top, 1)
                }

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.blue)

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
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .disabled(lists.isEmpty || isSaving)
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button(isSaving ? "Adding…" : "Add Reminder", action: submitTitle)
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedListID.isEmpty)
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 520)
        .onReceive(NotificationCenter.default.publisher(for: .quickAddTitleFocusRequested)) { _ in
            titleFieldFocused = true
        }
        .onExitCommand(perform: onEscape)
        .onChange(of: selectedListID) { _, listID in
            guard !listID.isEmpty else { return }
            UserDefaults.standard.set(listID, forKey: lastUsedListKey)
        }
        .onChange(of: hasDueDate) { _, hasDueDate in
            if !hasDueDate {
                hasDueTime = false
            }
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
        reminder.dueDateComponents = dueDateComponents

        do {
            try eventStore.save(reminder, commit: true)
            title = ""
            dueDate = Date()
            hasDueDate = false
            hasDueTime = false
            onSubmit()
        } catch {
            isSaving = false
            errorMessage = "Could not save reminder: \(error.localizedDescription)"
        }
    }

    @ViewBuilder
    private var dateControl: some View {
        if hasDueDate {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)

                DatePicker(
                    "Due date",
                    selection: $dueDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.field)

                Button {
                    hasDueDate = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .chipStyle()
            .disabled(isSaving)
        } else {
            Button {
                hasDueDate = true
            } label: {
                Label("Date", systemImage: "calendar")
            }
            .chipStyle()
            .buttonStyle(.borderless)
            .disabled(isSaving)
        }
    }

    @ViewBuilder
    private var timeControl: some View {
        if hasDueTime {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)

                DatePicker(
                    "Due time",
                    selection: $dueDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.field)

                Button {
                    hasDueTime = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .chipStyle()
            .disabled(isSaving)
        } else {
            Button {
                hasDueTime = true
            } label: {
                Label("Time", systemImage: "clock")
            }
            .chipStyle()
            .buttonStyle(.borderless)
            .disabled(isSaving)
        }
    }

    private var dueDateComponents: DateComponents? {
        guard hasDueDate else { return nil }

        let calendar = Calendar.current
        let components: Set<Calendar.Component> = hasDueTime
            ? [.year, .month, .day, .hour, .minute]
            : [.year, .month, .day]
        var dueDateComponents = calendar.dateComponents(components, from: dueDate)
        dueDateComponents.calendar = calendar

        if hasDueTime {
            dueDateComponents.timeZone = .current
        }

        return dueDateComponents
    }
}

private extension View {
    func chipStyle() -> some View {
        self
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension Notification.Name {
    static let quickAddTitleFocusRequested = Notification.Name("quickAddTitleFocusRequested")
}

#Preview {
    ContentView()
}
