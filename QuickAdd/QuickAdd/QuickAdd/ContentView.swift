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

private struct RejectedRecognitionOccurrence: Equatable {
    var range: NSRange
    let text: String
}

private enum QuickAddFocus: Hashable {
    case priority
    case addReminder
}

private struct MetadataFlowLayout: Layout {
    var spacing: CGFloat = 9
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maximumWidth = proposal.width ?? .greatestFiniteMagnitude
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maximumWidth {
                width = max(width, rowWidth)
                height += rowHeight + lineSpacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += rowWidth > 0 ? spacing : 0
            rowWidth += size.width
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: max(width, rowWidth), height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > bounds.minX, origin.x + spacing + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += rowHeight + lineSpacing
                rowHeight = 0
            }
            if origin.x > bounds.minX {
                origin.x += spacing
            }
            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct ContentView: View {
    private let onSubmit: () -> Void
    private let onEscape: () -> Void
    private let onLayoutChange: () -> Void
    private let lastUsedListKey = "lastUsedReminderListIdentifier"

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedListID = ""
    @State private var selectedPriority = 0
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
    @State private var recognizedRecurrenceResult: NaturalRecurrenceParseResult?
    @State private var recognizedPriorityResult: NaturalPriorityParseResult?
    @State private var smartPriorityIsActive = false
    @State private var priorityBeforeSmartSelection = 0
    @State private var applyingSmartPrioritySelection = false
    @State private var rejectedRecognitionOccurrences: [RejectedRecognitionOccurrence] = []
    @State private var focusRequestID = 0
    @State private var notesFocusRequestID = 0
    @State private var notesIsFocused = false
    @State private var lists: [EKCalendar] = []
    @State private var errorMessage: String?
    @State private var isLoadingLists = false
    @State private var isSaving = false
    @State private var eventStore = EKEventStore()
    @FocusState private var focusedControl: QuickAddFocus?
    init(
        onSubmit: @escaping () -> Void = {},
        onEscape: @escaping () -> Void = {},
        onLayoutChange: @escaping () -> Void = {}
    ) {
        self.onSubmit = onSubmit
        self.onEscape = onEscape
        self.onLayoutChange = onLayoutChange
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 17))

                    Text("Add to Reminders")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)

                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .leading) {
                        if title.isEmpty {
                            Text("Reminder title")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .allowsHitTesting(false)
                        }

                        HighlightingTextField(
                            text: $title,
                            recognizedRanges: recognizedRanges,
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
                            onMoveToNotes: {
                                hideSlashSuggestions()
                                notesFocusRequestID += 1
                            },
                            onRejectRecognition: rejectNaturalMetadata
                        )
                        .frame(height: 24)
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                        .padding(.top, 10)
                        .padding(.bottom, 4)

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

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                            .padding(.top, 5)

                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Add notes…")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 5)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }

                            NotesTextEditor(
                                text: $notes,
                                focusRequestID: notesFocusRequestID,
                                isEditable: !isSaving,
                                onMoveForward: {
                                    focusedControl = .priority
                                },
                                onMoveBackward: {
                                    focusRequestID += 1
                                },
                                onFocusChange: { isFocused in
                                    notesIsFocused = isFocused
                                }
                            )
                        }
                        .frame(height: notesEditorHeight)
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 7)

                    Divider()
                        .padding(.horizontal, 15)
                        .opacity(0.55)

                    MetadataFlowLayout {
                        listControl
                        dateControl

                        if hasDueDate {
                            timeControl
                        }

                        if recognizedRecurrenceResult != nil {
                            recurrenceControl
                        }

                        priorityControl
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
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
                        .controlSize(.regular)
                        .keyboardShortcut(.return, modifiers: .command)
                        .focused($focusedControl, equals: .addReminder)
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedListID.isEmpty)
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
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
        .onChange(of: selectedPriority) { _, priority in
            if smartPriorityIsActive, !applyingSmartPrioritySelection {
                priorityBeforeSmartSelection = priority
                smartPriorityIsActive = false
            }
            onLayoutChange()
        }
        .onChange(of: title) { previousTitle, title in
            updateRejectedRecognitionOccurrences(from: previousTitle, to: title)
            applySmartList(from: title)
            updateSlashSuggestions()
            applyNaturalMetadata(from: title)
            applyNaturalPriority(from: title)
            onLayoutChange()
        }
        .onChange(of: hasDueDate) { _, hasDueDate in
            if !hasDueDate {
                hasDueTime = false
            }
            onLayoutChange()
        }
        .onChange(of: hasDueTime) { _, _ in onLayoutChange() }
        .onChange(of: notes) { _, _ in onLayoutChange() }
        .onChange(of: notesIsFocused) { _, _ in onLayoutChange() }
        .onChange(of: errorMessage) { _, _ in onLayoutChange() }
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
        let trimmedTitle = cleanedTitleForSave
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
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            reminder.notes = trimmedNotes
        }
        reminder.priority = selectedPriority
        if let recurrence = recognizedRecurrenceResult?.recurrence {
            reminder.addRecurrenceRule(eventKitRule(for: recurrence))
        }

        do {
            try eventStore.save(reminder, commit: true)
            title = ""
            notes = ""
            dueDate = Date()
            hasDueDate = false
            hasDueTime = false
            selectedPriority = 0
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
                .font(.system(size: 8))
                .foregroundStyle(.secondary)

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
            .frame(maxWidth: 180)
            .disabled(lists.isEmpty || isSaving)
        }
        .metadataItemStyle()
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
            .metadataItemStyle(accented: true)
            .disabled(isSaving)
        } else {
            Button {
                manualDateOverride = true
                hasDueDate = true
            } label: {
                Label("Date", systemImage: "calendar")
            }
            .metadataItemStyle()
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
            .metadataItemStyle(accented: true)
            .disabled(isSaving)
        } else {
            Button {
                manualTimeOverride = true
                hasDueTime = true
            } label: {
                Label("Time", systemImage: "clock")
            }
            .metadataItemStyle()
            .buttonStyle(.borderless)
            .disabled(isSaving)
        }
    }

    private var recurrenceControl: some View {
        Label(recurrenceLabel, systemImage: "repeat")
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: 180)
            .metadataItemStyle(accented: true)
    }

    private var recurrenceLabel: String {
        guard let label = recognizedRecurrenceResult?.recurrence.label, let first = label.first else {
            return "Repeating"
        }
        return first.uppercased() + label.dropFirst()
    }

    private var priorityControl: some View {
        HStack(spacing: 4) {
            Image(systemName: "flag")
                .foregroundStyle(.secondary)

            Picker("Priority", selection: $selectedPriority) {
                Text("Priority").tag(0)
                Text("High").tag(1)
                Text("Medium").tag(5)
                Text("Low").tag(9)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .focused($focusedControl, equals: .priority)
            .disabled(isSaving)
        }
        .metadataItemStyle(accented: selectedPriority != 0)
    }

    private var notesEditorHeight: CGFloat {
        guard !notes.isEmpty || notesIsFocused else { return 26 }
        let lineCount = max(notes.split(separator: "\n", omittingEmptySubsequences: false).count, 1)
        return min(max(CGFloat(lineCount) * 18 + 8, 32), 76)
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

    private func applyNaturalMetadata(from title: String) {
        if let recurrenceResult = acceptedNaturalRecurrence(in: title) {
            recognizedRecurrenceResult = recurrenceResult
            recognizedDateResult = nil
            applyParsedDate(recurrenceResult.date, hasTime: recurrenceResult.hasTime)
            return
        }

        recognizedRecurrenceResult = nil
        guard let dateResult = acceptedNaturalDate(in: title) else {
            recognizedDateResult = nil
            clearProvisionalDate()
            return
        }

        recognizedDateResult = dateResult
        applyParsedDate(dateResult.date, hasTime: dateResult.hasTime)
    }

    private func applyParsedDate(_ parsedDate: Date, hasTime: Bool) {
        let calendar = Calendar.current
        if !manualDateOverride {
            let timeSource = manualTimeOverride ? dueDate : parsedDate
            dueDate = combining(dateFrom: parsedDate, timeFrom: timeSource, calendar: calendar)
            hasDueDate = true
        }

        if !manualTimeOverride {
            if hasTime {
                dueDate = combining(dateFrom: dueDate, timeFrom: parsedDate, calendar: calendar)
                hasDueTime = true
            } else {
                hasDueTime = false
            }
        }
    }

    private func acceptedNaturalRecurrence(in title: String) -> NaturalRecurrenceParseResult? {
        NaturalRecurrenceParser.parse(title, excluding: excludedRecognitionRanges(in: title))
    }

    private func acceptedNaturalDate(in title: String) -> NaturalDateParseResult? {
        NaturalDateParser.parse(title, excluding: excludedRecognitionRanges(in: title))
    }

    private var recognizedRanges: [NSRange] {
        [
            recognizedRecurrenceResult?.recognizedRange ?? recognizedDateResult?.recognizedRange,
            recognizedPriorityResult?.recognizedRange
        ].compactMap { $0 }
    }

    private var cleanedTitleForSave: String {
        var ranges = recognizedRanges
        if let listMatch = SlashListParser.matchingList(in: title, lists: lists) {
            ranges.append(NSRange(listMatch.range, in: title))
        }
        ranges.sort { $0.location > $1.location }

        var cleaned = title
        for range in ranges {
            guard let stringRange = Range(range, in: cleaned) else { continue }
            cleaned.replaceSubrange(stringRange, with: " ")
        }
        return cleaned
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func applyNaturalPriority(from title: String) {
        guard let result = NaturalPriorityParser.parse(
            title,
            excluding: excludedRecognitionRanges(in: title)
        ) else {
            recognizedPriorityResult = nil
            if smartPriorityIsActive {
                applyingSmartPrioritySelection = true
                selectedPriority = priorityBeforeSmartSelection
                DispatchQueue.main.async {
                    applyingSmartPrioritySelection = false
                }
                smartPriorityIsActive = false
            }
            return
        }

        recognizedPriorityResult = result
        if !smartPriorityIsActive {
            priorityBeforeSmartSelection = selectedPriority
            smartPriorityIsActive = true
        }
        applyingSmartPrioritySelection = true
        selectedPriority = result.value
        DispatchQueue.main.async {
            applyingSmartPrioritySelection = false
        }
    }

    private func excludedRecognitionRanges(in title: String) -> [NSRange] {
        var excludedRanges = rejectedRecognitionOccurrences.map(\.range)
        if let fragment = SlashListParser.fragment(in: title) {
            excludedRanges.append(NSRange(fragment.range, in: title))
        }
        return excludedRanges
    }

    private func rejectNaturalMetadata(at range: NSRange) {
        let text: String?
        if recognizedPriorityResult.map({ NSEqualRanges($0.recognizedRange, range) }) == true {
            text = recognizedPriorityResult?.recognizedText
        } else if recognizedRecurrenceResult.map({ NSEqualRanges($0.recognizedRange, range) }) == true {
            text = recognizedRecurrenceResult?.recognizedText
        } else if recognizedDateResult.map({ NSEqualRanges($0.recognizedRange, range) }) == true {
            text = recognizedDateResult?.recognizedText
        } else {
            text = nil
        }
        guard let text else { return }

        let rejection = RejectedRecognitionOccurrence(range: range, text: text)
        if !rejectedRecognitionOccurrences.contains(rejection) {
            rejectedRecognitionOccurrences.append(rejection)
        }
        applyNaturalMetadata(from: title)
        applyNaturalPriority(from: title)
    }

    private func updateRejectedRecognitionOccurrences(from oldTitle: String, to newTitle: String) {
        guard oldTitle != newTitle, !rejectedRecognitionOccurrences.isEmpty else { return }

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

        rejectedRecognitionOccurrences = rejectedRecognitionOccurrences.compactMap { occurrence in
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

    private func eventKitRule(for recurrence: NaturalRecurrence) -> EKRecurrenceRule {
        let frequency: EKRecurrenceFrequency
        switch recurrence.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        }

        let weekdays = recurrence.weekdays.map { weekday in
            let eventKitWeekday = EKWeekday(rawValue: weekday.day)!
            return EKRecurrenceDayOfWeek(eventKitWeekday, weekNumber: weekday.weekNumber ?? 0)
        }

        if weekdays.isEmpty {
            return EKRecurrenceRule(
                recurrenceWith: frequency,
                interval: recurrence.interval,
                end: nil
            )
        }

        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: recurrence.interval,
            daysOfTheWeek: weekdays,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
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
    func metadataItemStyle(accented: Bool = false) -> some View {
        self
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(accented ? Color.blue : Color.secondary)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
    }
}

extension Notification.Name {
    static let quickAddTitleFocusRequested = Notification.Name("quickAddTitleFocusRequested")
}

#Preview {
    ContentView()
}
