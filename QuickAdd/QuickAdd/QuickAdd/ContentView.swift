//
//  ContentView.swift
//  QuickAdd
//
//  Created by Alex on 8/22/26.
//

import EventKit
import SwiftUI

private struct SlashSuggestion: Identifiable {
    enum Kind {
        case list
        case create
    }

    let kind: Kind
    let id: String
    let title: String
}

private struct RejectedDateOccurrence: Equatable {
    var range: NSRange
    let text: String
}

struct ContentView: View {
    private let onSubmit: () -> Void
    private let onEscape: () -> Void
    private let lastUsedListKey = "lastUsedReminderListIdentifier"

    @State private var title = ""
    @State private var selectedListID = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var hasDueTime = false
    @State private var manualDateOverride = false
    @State private var manualTimeOverride = false
    @State private var slashSuggestions: [SlashSuggestion] = []
    @State private var selectedSuggestionIndex = 0
    @State private var smartListIsActive = false
    @State private var listBeforeSmartSelection = ""
    @State private var applyingSmartListSelection = false
    @State private var recognizedDateResult: NaturalDateParseResult?
    @State private var rejectedDateOccurrences: [RejectedDateOccurrence] = []
    @State private var focusRequestID = 0
    @State private var lists: [EKCalendar] = []
    @State private var errorMessage: String?
    @State private var isLoadingLists = false
    @State private var isSaving = false
    @State private var eventStore = EKEventStore()
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
                    ZStack(alignment: .leading) {
                        if title.isEmpty {
                            Text("Reminder title")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .allowsHitTesting(false)
                        }

                        HighlightingTextField(
                            text: $title,
                            recognizedRange: recognizedDateResult?.recognizedRange,
                            focusRequestID: focusRequestID,
                            onSubmit: {
                                if !acceptSuggestion() {
                                    submitTitle()
                                }
                            },
                            onEscape: {
                                if slashSuggestions.isEmpty {
                                    onEscape()
                                } else {
                                    hideSlashSuggestions()
                                }
                            },
                            onMoveSuggestion: moveSuggestionSelection,
                            onRejectRecognition: rejectNaturalDate
                        )
                        .frame(height: 24)
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                        .padding(.top, 11)

                    if !slashSuggestions.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(slashSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                                    Button {
                                        choose(suggestion)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(suggestion.kind == .create ? "+" : "/")
                                                .foregroundStyle(.blue)
                                                .fontWeight(.bold)
                                            Text(suggestion.kind == .create ? "Create \"\(suggestion.title)\"" : suggestion.title)
                                            Spacer()
                                        }
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 10)
                                        .frame(height: 34)
                                        .background(index == selectedSuggestionIndex ? Color.blue.opacity(0.11) : .clear)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: min(CGFloat(slashSuggestions.count) * 34, 68))
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.horizontal, 15)
                    }

                    HStack(spacing: 7) {
                        listControl
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
            focusRequestID += 1
        }
        .onExitCommand(perform: onEscape)
        .onChange(of: selectedListID) { _, listID in
            guard !listID.isEmpty else { return }
            UserDefaults.standard.set(listID, forKey: lastUsedListKey)
            updateInlineListForManualSelection(listID)
        }
        .onChange(of: title) { previousTitle, title in
            updateRejectedDateOccurrences(from: previousTitle, to: title)
            applySmartList(from: title)
            updateSlashSuggestions()
            applyNaturalDate(from: title)
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
            let lhsInbox = $0.title.caseInsensitiveCompare("Inbox") == .orderedSame
            let rhsInbox = $1.title.caseInsensitiveCompare("Inbox") == .orderedSame
            if lhsInbox != rhsInbox { return lhsInbox }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
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
        let titleWithoutDate = recognizedDateResult?.title ?? title
        let trimmedTitle = SlashListParser.removingMatchedList(from: titleWithoutDate, lists: lists)
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
    private var listControl: some View {
        HStack(spacing: 4) {
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
        .chipStyle()
    }

    @ViewBuilder
    private var dateControl: some View {
        if hasDueDate {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)

                DatePicker(
                    "Due date",
                    selection: manualDateBinding,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.field)

                Button {
                    manualDateOverride = true
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
                manualDateOverride = true
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
                    selection: manualTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.field)

                Button {
                    manualTimeOverride = true
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
                manualTimeOverride = true
                hasDueTime = true
            } label: {
                Label("Time", systemImage: "clock")
            }
            .chipStyle()
            .buttonStyle(.borderless)
            .disabled(isSaving)
        }
    }

    private var manualDateBinding: Binding<Date> {
        Binding(
            get: { dueDate },
            set: {
                dueDate = $0
                manualDateOverride = true
            }
        )
    }

    private var manualTimeBinding: Binding<Date> {
        Binding(
            get: { dueDate },
            set: {
                dueDate = $0
                manualTimeOverride = true
            }
        )
    }

    private func applyNaturalDate(from title: String) {
        guard let result = acceptedNaturalDate(in: title) else {
            recognizedDateResult = nil
            clearProvisionalDate()
            return
        }

        recognizedDateResult = result

        let calendar = Calendar.current
        if !manualDateOverride {
            let timeSource = manualTimeOverride ? dueDate : result.date
            dueDate = combining(dateFrom: result.date, timeFrom: timeSource, calendar: calendar)
            hasDueDate = true
        }

        if !manualTimeOverride {
            if result.hasTime {
                dueDate = combining(dateFrom: dueDate, timeFrom: result.date, calendar: calendar)
                hasDueTime = true
            } else {
                hasDueTime = false
            }
        }
    }

    private func acceptedNaturalDate(in title: String) -> NaturalDateParseResult? {
        var excludedRanges = rejectedDateOccurrences.map(\.range)
        if let fragment = SlashListParser.fragment(in: title) {
            excludedRanges.append(NSRange(fragment.range, in: title))
        }
        return NaturalDateParser.parse(title, excluding: excludedRanges)
    }

    private func rejectNaturalDate() {
        guard let recognizedDateResult else { return }
        let rejection = RejectedDateOccurrence(
            range: recognizedDateResult.recognizedRange,
            text: recognizedDateResult.recognizedText
        )
        if !rejectedDateOccurrences.contains(rejection) {
            rejectedDateOccurrences.append(rejection)
        }
        applyNaturalDate(from: title)
    }

    private func updateRejectedDateOccurrences(from oldTitle: String, to newTitle: String) {
        guard oldTitle != newTitle, !rejectedDateOccurrences.isEmpty else { return }

        let oldText = oldTitle as NSString
        let newText = newTitle as NSString
        var commonPrefixLength = 0
        while commonPrefixLength < oldText.length,
              commonPrefixLength < newText.length,
              oldText.character(at: commonPrefixLength) == newText.character(at: commonPrefixLength) {
            commonPrefixLength += 1
        }

        var commonSuffixLength = 0
        while commonSuffixLength < oldText.length - commonPrefixLength,
              commonSuffixLength < newText.length - commonPrefixLength,
              oldText.character(at: oldText.length - commonSuffixLength - 1)
                == newText.character(at: newText.length - commonSuffixLength - 1) {
            commonSuffixLength += 1
        }

        let editedOldRange = NSRange(
            location: commonPrefixLength,
            length: oldText.length - commonPrefixLength - commonSuffixLength
        )
        let replacementLength = newText.length - commonPrefixLength - commonSuffixLength
        let locationDelta = replacementLength - editedOldRange.length

        rejectedDateOccurrences = rejectedDateOccurrences.compactMap { occurrence in
            var updated = occurrence
            let occurrenceEnd = NSMaxRange(occurrence.range)

            if editedOldRange.length == 0 {
                if editedOldRange.location <= occurrence.range.location {
                    updated.range.location += locationDelta
                } else if editedOldRange.location < occurrenceEnd {
                    return nil
                }
            } else if NSMaxRange(editedOldRange) <= occurrence.range.location {
                updated.range.location += locationDelta
            } else if editedOldRange.location < occurrenceEnd {
                return nil
            }

            guard updated.range.location >= 0,
                  NSMaxRange(updated.range) <= newText.length,
                  newText.substring(with: updated.range) == updated.text else { return nil }
            return updated
        }
    }

    private func clearProvisionalDate() {
        if !manualDateOverride {
            hasDueDate = false
        }
        if !manualTimeOverride {
            hasDueTime = false
        }
    }

    private func updateSlashSuggestions() {
        guard let fragment = SlashListParser.fragment(in: title) else {
            hideSlashSuggestions()
            return
        }

        let matches = SlashListParser.suggestions(for: fragment, lists: lists)
        var suggestions = matches.map {
            SlashSuggestion(kind: .list, id: $0.calendarIdentifier, title: $0.title)
        }
        let requestedName = fragment.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let exactMatch = lists.contains { $0.title.caseInsensitiveCompare(requestedName) == .orderedSame }
        if !requestedName.isEmpty && !exactMatch {
            suggestions.append(SlashSuggestion(kind: .create, id: "create:\(requestedName)", title: requestedName))
        }

        slashSuggestions = suggestions
        selectedSuggestionIndex = min(selectedSuggestionIndex, max(suggestions.count - 1, 0))
    }

    private func hideSlashSuggestions() {
        slashSuggestions = []
        selectedSuggestionIndex = 0
    }

    private func moveSuggestionSelection(by offset: Int) -> Bool {
        guard !slashSuggestions.isEmpty else { return false }
        selectedSuggestionIndex = (selectedSuggestionIndex + offset + slashSuggestions.count) % slashSuggestions.count
        return true
    }

    private func acceptSuggestion() -> Bool {
        guard !slashSuggestions.isEmpty else { return false }
        let suggestion = slashSuggestions[selectedSuggestionIndex]
        guard suggestion.kind == .list else { return true }
        choose(suggestion)
        return true
    }

    private func choose(_ suggestion: SlashSuggestion) {
        if suggestion.kind == .create {
            createList(named: suggestion.title)
            return
        }
        selectList(id: suggestion.id, title: suggestion.title)
    }

    private func selectList(id: String, title: String) {
        guard let fragment = SlashListParser.fragment(in: self.title) else { return }
        self.title = SlashListParser.removing(fragment, from: self.title)
        smartListIsActive = false
        listBeforeSmartSelection = ""
        applyingSmartListSelection = true
        selectedListID = id
        DispatchQueue.main.async {
            applyingSmartListSelection = false
        }
        hideSlashSuggestions()
    }

    private func createList(named title: String) {
        guard let source = eventStore.defaultCalendarForNewReminders()?.source else {
            errorMessage = "Could not create Reminders list."
            return
        }

        let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
        calendar.title = title
        calendar.source = source

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            lists.append(calendar)
            lists.sort {
                let lhsInbox = $0.title.caseInsensitiveCompare("Inbox") == .orderedSame
                let rhsInbox = $1.title.caseInsensitiveCompare("Inbox") == .orderedSame
                if lhsInbox != rhsInbox { return lhsInbox }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            selectList(id: calendar.calendarIdentifier, title: calendar.title)
        } catch {
            errorMessage = "Could not create Reminders list: \(error.localizedDescription)"
        }
    }

    private func applySmartList(from title: String) {
        guard let match = SlashListParser.matchingList(in: title, lists: lists) else {
            if smartListIsActive, lists.contains(where: { $0.calendarIdentifier == listBeforeSmartSelection }) {
                applyingSmartListSelection = true
                selectedListID = listBeforeSmartSelection
                DispatchQueue.main.async {
                    applyingSmartListSelection = false
                }
            }
            smartListIsActive = false
            return
        }

        if !smartListIsActive {
            listBeforeSmartSelection = selectedListID
            smartListIsActive = true
        }
        applyingSmartListSelection = true
        selectedListID = match.listID
        DispatchQueue.main.async {
            applyingSmartListSelection = false
        }
    }

    private func updateInlineListForManualSelection(_ listID: String) {
        guard smartListIsActive, !applyingSmartListSelection,
              lists.contains(where: { $0.calendarIdentifier == listID }),
              SlashListParser.matchingList(in: title, lists: lists) != nil else { return }
        title = SlashListParser.removingMatchedList(from: title, lists: lists)
        smartListIsActive = false
        listBeforeSmartSelection = ""
    }

    private func combining(dateFrom date: Date, timeFrom time: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components) ?? date
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
