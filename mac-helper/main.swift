import EventKit
import Foundation

let store = EKEventStore()

struct HelperFailure: Error {
    let code: String
    let message: String
}

enum RemindersPermission {
    case granted
    case denied
    case restricted
    case failed(String)
}

func stderr(_ message: String) {
    FileHandle.standardError.write(
        Data((message + "\n").utf8)
    )
}

func send(_ object: [String: Any]) {
    do {
        let data = try JSONSerialization.data(
            withJSONObject: object
        )

        var length = UInt32(data.count).littleEndian

        let header = withUnsafeBytes(of: &length) {
            Data($0)
        }

        FileHandle.standardOutput.write(header)
        FileHandle.standardOutput.write(data)
    } catch {
        stderr("Could not encode response: \(error)")
    }
}

func readExact(_ count: Int) -> Data? {
    var result = Data()

    while result.count < count {
        let chunk = FileHandle.standardInput.readData(
            ofLength: count - result.count
        )

        if chunk.isEmpty {
            return nil
        }

        result.append(chunk)
    }

    return result
}

func readMessage() -> [String: Any]? {
    guard let header = readExact(4) else {
        return nil
    }

    let bytes = [UInt8](header)

    let length =
        UInt32(bytes[0]) |
        (UInt32(bytes[1]) << 8) |
        (UInt32(bytes[2]) << 16) |
        (UInt32(bytes[3]) << 24)

    guard length > 0, length < 1_048_576 else {
        stderr("Invalid message length: \(length)")
        return nil
    }

    guard let body = readExact(Int(length)) else {
        return nil
    }

    do {
        return try JSONSerialization
            .jsonObject(with: body) as? [String: Any]
    } catch {
        stderr("Invalid JSON: \(error)")
        return nil
    }
}

func requestRemindersAccess() -> RemindersPermission {
    let semaphore = DispatchSemaphore(value: 0)

    var granted = false
    var accessError: Error?

    store.requestFullAccessToReminders { success, error in
        granted = success
        accessError = error
        semaphore.signal()
    }

    semaphore.wait()

    if granted {
        return .granted
    }

    let status = EKEventStore.authorizationStatus(
        for: .reminder
    )

    if status == .denied {
        return .denied
    }

    if status == .restricted {
        return .restricted
    }

    return .failed(
        accessError?.localizedDescription ??
        "Could not obtain Reminders access."
    )
}

func permissionErrorResponse(
    for permission: RemindersPermission
) -> [String: Any]? {
    switch permission {
    case .granted:
        return nil

    case .denied:
        return [
            "ok": false,
            "code": "reminders_permission_denied",
            "error": "Reminders access was denied."
        ]

    case .restricted:
        return [
            "ok": false,
            "code": "reminders_permission_restricted",
            "error": "Reminders access is restricted on this Mac."
        ]

    case .failed(let message):
        return [
            "ok": false,
            "code": "reminders_permission_error",
            "error": message
        ]
    }
}

func failureResponse(_ failure: HelperFailure) -> [String: Any] {
    [
        "ok": false,
        "code": failure.code,
        "error": failure.message
    ]
}

func reminderLists() -> [[String: String]] {
    store.calendars(for: .reminder)
        .sorted {
            $0.title.localizedCaseInsensitiveCompare(
                $1.title
            ) == .orderedAscending
        }
        .map {
            [
                "id": $0.calendarIdentifier,
                "title": $0.title
            ]
        }
}

func createReminderList(
    named rawName: String
) -> [String: Any] {
    let name = rawName.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard !name.isEmpty else {
        return failureResponse(
            HelperFailure(
                code: "invalid_request",
                message: "List name cannot be empty."
            )
        )
    }

    if let existing =
        store.calendars(for: .reminder)
            .first(where: {
                $0.title.caseInsensitiveCompare(name)
                    == .orderedSame
            })
    {
        return [
            "ok": true,
            "id": existing.calendarIdentifier,
            "title": existing.title,
            "created": false
        ]
    }

    let calendar = EKCalendar(
        for: .reminder,
        eventStore: store
    )

    calendar.title = name

    if let source =
        store.defaultCalendarForNewReminders()?.source
    {
        calendar.source = source
    } else if let source =
        store.calendars(for: .reminder).first?.source
    {
        calendar.source = source
    } else {
        return failureResponse(
            HelperFailure(
                code: "eventkit_source_unavailable",
                message: "Could not determine a Reminders account for the new list."
            )
        )
    }

    do {
        try store.saveCalendar(
            calendar,
            commit: true
        )

        return [
            "ok": true,
            "id": calendar.calendarIdentifier,
            "title": calendar.title,
            "created": true
        ]
    } catch {
        return failureResponse(
            HelperFailure(
                code: "eventkit_save_failed",
                message: error.localizedDescription
            )
        )
    }
}

func localGregorianCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
}

func parseTime(_ rawValue: String?) throws -> (hour: Int, minute: Int)? {
    guard let rawValue, !rawValue.isEmpty else {
        return nil
    }

    let parts = rawValue.split(separator: ":")

    guard
        parts.count == 2,
        let hour = Int(parts[0]),
        let minute = Int(parts[1]),
        (0...23).contains(hour),
        (0...59).contains(minute)
    else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid reminder time."
        )
    }

    return (hour, minute)
}

func parseISODate(
    _ value: String,
    calendar: Calendar
) throws -> Date {
    let parts = value.split(separator: "-")

    guard
        parts.count == 3,
        let year = Int(parts[0]),
        let month = Int(parts[1]),
        let day = Int(parts[2])
    else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid reminder date."
        )
    }

    var components = DateComponents()
    components.calendar = calendar
    components.timeZone = calendar.timeZone
    components.year = year
    components.month = month
    components.day = day

    guard let date = calendar.date(from: components) else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid reminder date."
        )
    }

    let resolved = calendar.dateComponents(
        [.year, .month, .day],
        from: date
    )

    guard
        resolved.year == year,
        resolved.month == month,
        resolved.day == day
    else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid reminder date."
        )
    }

    return date
}

func dueDateComponents(
    from rawValue: String?,
    time rawTime: String?
) throws -> DateComponents? {
    guard
        let rawValue,
        rawValue != "none"
    else {
        return nil
    }

    let calendar = localGregorianCalendar()
    let today = calendar.startOfDay(for: Date())
    let date: Date

    switch rawValue {
    case "today":
        date = today

    case "tomorrow":
        guard let result = calendar.date(
            byAdding: .day,
            value: 1,
            to: today
        ) else {
            throw HelperFailure(
                code: "invalid_request",
                message: "Could not resolve tomorrow."
            )
        }
        date = result

    case "weekend":
        let weekday = calendar.component(
            .weekday,
            from: today
        )
        let daysUntilSaturday = (7 - weekday + 7) % 7

        guard let result = calendar.date(
            byAdding: .day,
            value: daysUntilSaturday,
            to: today
        ) else {
            throw HelperFailure(
                code: "invalid_request",
                message: "Could not resolve the weekend."
            )
        }
        date = result

    case "nextweek":
        guard let result = calendar.nextDate(
            after: today,
            matching: DateComponents(weekday: 2),
            matchingPolicy: .nextTime,
            direction: .forward
        ) else {
            throw HelperFailure(
                code: "invalid_request",
                message: "Could not resolve next week."
            )
        }
        date = result

    default:
        date = try parseISODate(
            rawValue,
            calendar: calendar
        )
    }

    let dateValues = calendar.dateComponents(
        [.year, .month, .day],
        from: date
    )

    var components = DateComponents()
    components.calendar = calendar
    components.timeZone = calendar.timeZone
    components.year = dateValues.year
    components.month = dateValues.month
    components.day = dateValues.day

    if let time = try parseTime(rawTime) {
        components.hour = time.hour
        components.minute = time.minute
    }

    return components
}

func recurrenceFrequency(
    from value: String
) throws -> EKRecurrenceFrequency {
    switch value {
    case "daily":
        return .daily
    case "weekly":
        return .weekly
    case "monthly":
        return .monthly
    case "yearly":
        return .yearly
    default:
        throw HelperFailure(
            code: "invalid_request",
            message: "Unsupported recurrence frequency."
        )
    }
}

func recurrenceWeekday(from value: Int) throws -> EKWeekday {
    guard let weekday = EKWeekday(rawValue: value) else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid recurrence weekday."
        )
    }

    return weekday
}

func recurrenceRule(
    from rawValue: Any?
) throws -> EKRecurrenceRule? {
    guard
        let rawValue,
        !(rawValue is NSNull)
    else {
        return nil
    }

    guard
        let recurrence = rawValue as? [String: Any],
        let rawFrequency = recurrence["frequency"] as? String
    else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid recurrence payload."
        )
    }

    let frequency = try recurrenceFrequency(
        from: rawFrequency
    )

    let interval = recurrence["interval"] as? Int ?? 1

    guard (1...999).contains(interval) else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid recurrence interval."
        )
    }

    guard let rawWeekdays = recurrence["weekdays"] else {
        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: interval,
            end: nil
        )
    }

    guard let rawWeekdays = rawWeekdays as? [Any] else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid recurrence weekdays."
        )
    }

    var weekdays: [EKRecurrenceDayOfWeek] = []

    for rawWeekday in rawWeekdays {
        if let day = rawWeekday as? Int {
            weekdays.append(
                EKRecurrenceDayOfWeek(
                    try recurrenceWeekday(from: day)
                )
            )
            continue
        }

        guard
            let ordinal = rawWeekday as? [String: Any],
            let day = ordinal["day"] as? Int,
            let weekNumber = ordinal["weekNumber"] as? Int,
            weekNumber == -1 || (1...5).contains(weekNumber)
        else {
            throw HelperFailure(
                code: "invalid_request",
                message: "Invalid ordinal recurrence weekday."
            )
        }

        weekdays.append(
            EKRecurrenceDayOfWeek(
                try recurrenceWeekday(from: day),
                weekNumber: weekNumber
            )
        )
    }

    guard !weekdays.isEmpty else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Recurrence weekdays cannot be empty."
        )
    }

    return EKRecurrenceRule(
        recurrenceWith: frequency,
        interval: interval,
        daysOfTheWeek: weekdays,
        daysOfTheMonth: nil,
        monthsOfTheYear: nil,
        weeksOfTheYear: nil,
        daysOfTheYear: nil,
        setPositions: nil,
        end: nil
    )
}

func reminderPriority(from rawValue: Any?) throws -> Int {
    let priority = rawValue as? Int ?? 0

    guard [0, 1, 5, 9].contains(priority) else {
        throw HelperFailure(
            code: "invalid_request",
            message: "Invalid reminder priority."
        )
    }

    return priority
}

func createReminder(
    from request: [String: Any]
) -> [String: Any] {
    do {
        guard let rawTitle = request["title"] as? String else {
            throw HelperFailure(
                code: "invalid_request",
                message: "Missing reminder title."
            )
        }

        let title = rawTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !title.isEmpty else {
            throw HelperFailure(
                code: "invalid_request",
                message: "Missing reminder title."
            )
        }

        guard
            let listID = request["listId"] as? String,
            let list = store.calendars(for: .reminder)
                .first(where: {
                    $0.calendarIdentifier == listID
                })
        else {
            throw HelperFailure(
                code: "list_not_found",
                message: "Reminder list not found."
            )
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = list

        let userNotes = request["notes"] as? String ?? ""

        if !userNotes.isEmpty {
            reminder.notes = userNotes
        }

        reminder.priority = try reminderPriority(
            from: request["priority"]
        )

        let rawURL = request["url"] as? String ?? ""
        if !rawURL.isEmpty {
            guard
                let url = URL(string: rawURL),
                let scheme = url.scheme?.lowercased(),
                scheme == "http" || scheme == "https"
            else {
                throw HelperFailure(
                    code: "invalid_request",
                    message: "Invalid reminder URL."
                )
            }

            reminder.url = url
        }

        reminder.dueDateComponents = try dueDateComponents(
            from: request["due"] as? String,
            time: request["time"] as? String
        )

        if let rule = try recurrenceRule(
            from: request["recurrence"]
        ) {
            reminder.addRecurrenceRule(rule)
        }

        do {
            try store.save(reminder, commit: true)
        } catch {
            throw HelperFailure(
                code: "eventkit_save_failed",
                message: error.localizedDescription
            )
        }

        if !rawURL.isEmpty {
            let externalIdentifier =
                reminder.calendarItemExternalIdentifier ?? ""

            var richLinkResult: Int32 = 1

            if !externalIdentifier.isEmpty {
                var errorBuffer =
                    [CChar](repeating: 0, count: 2048)

                richLinkResult = listID.withCString { listIDCString in
                    externalIdentifier.withCString { externalCString in
                        rawURL.withCString { urlCString in
                            add_rich_link_to_existing_reminder(
                                listIDCString,
                                externalCString,
                                urlCString,
                                &errorBuffer,
                                Int32(errorBuffer.count)
                            )
                        }
                    }
                }

            }

            if richLinkResult != 0 {
                var fallbackNotes = userNotes

                if !fallbackNotes.contains(rawURL) {
                    if fallbackNotes.isEmpty {
                        fallbackNotes = rawURL
                    } else {
                        fallbackNotes += "\n\n" + rawURL
                    }
                }

                reminder.notes = fallbackNotes

                do {
                    try store.save(reminder, commit: true)
                } catch {
                    throw HelperFailure(
                        code: "eventkit_save_failed",
                        message: error.localizedDescription
                    )
                }
            }
        }

        return [
            "ok": true,
            "title": title,
            "list": list.title
        ]
    } catch let failure as HelperFailure {
        return failureResponse(failure)
    } catch {
        return failureResponse(
            HelperFailure(
                code: "eventkit_error",
                message: error.localizedDescription
            )
        )
    }
}

#if HELPER_MAPPING_TESTS
func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

func decodedTestRequest(_ json: String) throws -> [String: Any] {
    let data = Data(json.utf8)

    guard let request = try JSONSerialization
        .jsonObject(with: data) as? [String: Any]
    else {
        preconditionFailure("Could not decode test request")
    }

    return request
}

let noRecurrenceRequests = try [
    #"{"action":"add","title":"Plain reminder","url":"https://example.com","listId":"inbox","due":"none","time":"","recurrence":null,"priority":0,"notes":""}"#,
    #"{"action":"add","title":"Reminder with notes","url":"https://example.com","listId":"inbox","due":"none","time":"","recurrence":null,"priority":0,"notes":"Two lines of notes"}"#,
    #"{"action":"add","title":"High priority reminder","url":"https://example.com","listId":"inbox","due":"none","time":"","recurrence":null,"priority":1,"notes":""}"#,
    #"{"action":"add","title":"Timed reminder","url":"https://example.com","listId":"inbox","due":"2026-09-14","time":"15:30","recurrence":null,"priority":0,"notes":""}"#
].map(decodedTestRequest)

for request in noRecurrenceRequests {
    let rule = try recurrenceRule(
        from: request["recurrence"]
    )
    require(rule == nil, "JSON null unexpectedly created a recurrence rule")
    _ = try reminderPriority(from: request["priority"])
    _ = try dueDateComponents(
        from: request["due"] as? String,
        time: request["time"] as? String
    )
}

let omittedRecurrence = try recurrenceRule(from: nil)
require(omittedRecurrence == nil, "Omitted recurrence unexpectedly created a rule")

let everyDayRequest = try decodedTestRequest(
    #"{"recurrence":{"frequency":"daily","interval":1,"label":"Every day"}}"#
)
let everyDayRule = try recurrenceRule(
    from: everyDayRequest["recurrence"]
)
require(everyDayRule?.frequency == .daily, "Every-day payload failed")

let firstMondayAtNoonRequest = try decodedTestRequest(
    #"{"due":"2026-09-07","time":"12:00","recurrence":{"frequency":"monthly","interval":1,"label":"Every 1st Monday","weekdays":[{"day":2,"weekNumber":1}]}}"#
)
let firstMondayAtNoonRule = try recurrenceRule(
    from: firstMondayAtNoonRequest["recurrence"]
)
require(firstMondayAtNoonRule?.frequency == .monthly, "First-Monday payload failed")
require(firstMondayAtNoonRule?.daysOfTheWeek?.first?.dayOfTheWeek == .monday, "First-Monday weekday failed")
require(firstMondayAtNoonRule?.daysOfTheWeek?.first?.weekNumber == 1, "First-Monday ordinal failed")
let noon = try dueDateComponents(
    from: firstMondayAtNoonRequest["due"] as? String,
    time: firstMondayAtNoonRequest["time"] as? String
)
require(noon?.hour == 12, "Noon time mapping failed")

do {
    _ = try recurrenceRule(from: ["interval": 1])
    preconditionFailure("Malformed recurrence payload was accepted")
} catch let failure as HelperFailure {
    require(failure.code == "invalid_request", "Malformed recurrence returned the wrong code")
    require(failure.message == "Invalid recurrence payload.", "Malformed recurrence returned the wrong message")
}

let allDay = try dueDateComponents(
    from: "2026-09-14",
    time: nil
)
require(allDay?.year == 2026, "All-day year mapping failed")
require(allDay?.month == 9, "All-day month mapping failed")
require(allDay?.day == 14, "All-day day mapping failed")
require(allDay?.hour == nil, "All-day reminder unexpectedly has a time")

let timed = try dueDateComponents(
    from: "2026-09-14",
    time: "15:30"
)
require(timed?.hour == 15, "Timed reminder hour mapping failed")
require(timed?.minute == 30, "Timed reminder minute mapping failed")

let daily = try recurrenceRule(from: [
    "frequency": "daily",
    "interval": 1
])
require(daily?.frequency == .daily, "Daily recurrence frequency failed")
require(daily?.interval == 1, "Daily recurrence interval failed")

let weekdays = try recurrenceRule(from: [
    "frequency": "weekly",
    "interval": 1,
    "weekdays": [2, 3, 4, 5, 6]
])
require(weekdays?.frequency == .weekly, "Weekday recurrence frequency failed")
require(weekdays?.daysOfTheWeek?.count == 5, "Weekday recurrence days failed")

let firstMonday = try recurrenceRule(from: [
    "frequency": "monthly",
    "interval": 1,
    "weekdays": [["day": 2, "weekNumber": 1]]
])
require(firstMonday?.frequency == .monthly, "First Monday frequency failed")
require(firstMonday?.daysOfTheWeek?.first?.dayOfTheWeek == .monday, "First Monday weekday failed")
require(firstMonday?.daysOfTheWeek?.first?.weekNumber == 1, "First Monday ordinal failed")

let lastFriday = try recurrenceRule(from: [
    "frequency": "monthly",
    "interval": 1,
    "weekdays": [["day": 6, "weekNumber": -1]]
])
require(lastFriday?.daysOfTheWeek?.first?.dayOfTheWeek == .friday, "Last Friday weekday failed")
require(lastFriday?.daysOfTheWeek?.first?.weekNumber == -1, "Last Friday ordinal failed")

let quarterly = try recurrenceRule(from: [
    "frequency": "monthly",
    "interval": 3
])
require(quarterly?.frequency == .monthly, "Quarterly frequency failed")
require(quarterly?.interval == 3, "Quarterly interval failed")

let noPriority = try reminderPriority(from: 0)
let highPriority = try reminderPriority(from: 1)
let mediumPriority = try reminderPriority(from: 5)
let lowPriority = try reminderPriority(from: 9)
require(noPriority == 0, "No-priority mapping failed")
require(highPriority == 1, "High-priority mapping failed")
require(mediumPriority == 5, "Medium-priority mapping failed")
require(lowPriority == 9, "Low-priority mapping failed")

print("EventKit mapping tests passed")
#else
let permission = requestRemindersAccess()

while let request = readMessage() {
    if let error = permissionErrorResponse(
        for: permission
    ) {
        send(error)
        continue
    }

    guard let action = request["action"] as? String else {
        send(
            failureResponse(
                HelperFailure(
                    code: "invalid_request",
                    message: "Missing action."
                )
            )
        )
        continue
    }

    switch action {
    case "lists":
        send([
            "ok": true,
            "lists": reminderLists()
        ])

    case "add":
        send(createReminder(from: request))

    case "createList":
        guard let name = request["name"] as? String else {
            send(
                failureResponse(
                    HelperFailure(
                        code: "invalid_request",
                        message: "Missing list name."
                    )
                )
            )
            continue
        }

        send(createReminderList(named: name))

    default:
        send(
            failureResponse(
                HelperFailure(
                    code: "unknown_action",
                    message: "Unknown action: \(action)"
                )
            )
        )
    }
}
#endif
