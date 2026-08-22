import Foundation
import EventKit

let store = EKEventStore()

@_silgen_name("add_rich_reminder")
func addRichReminder(
    _ listID: UnsafePointer<CChar>,
    _ title: UnsafePointer<CChar>,
    _ url: UnsafePointer<CChar>,
    _ imageURL: UnsafePointer<CChar>,
    _ year: Int32,
    _ month: Int32,
    _ day: Int32,
    _ hour: Int32,
    _ minute: Int32,
    _ hasTime: Int32,
    _ recurrenceFrequency: Int32,
    _ recurrenceInterval: Int32,
    _ recurrenceJSON: UnsafePointer<CChar>,
    _ priority: Int32,
    _ notes: UnsafePointer<CChar>,
    _ tagsJSON: UnsafePointer<CChar>,
    _ errorBuffer: UnsafeMutablePointer<CChar>,
    _ errorBufferLength: Int32
) -> Int32

@_silgen_name("load_reminder_tags_json")
func loadReminderTagsJSON(
    _ jsonBuffer:
        UnsafeMutablePointer<CChar>,
    _ jsonBufferLength: Int32,
    _ errorBuffer:
        UnsafeMutablePointer<CChar>,
    _ errorBufferLength: Int32
) -> Int32

func loadReminderTagNames() -> [String] {
    var jsonBuffer =
        [CChar](
            repeating: 0,
            count: 65_536
        )

    var errorBuffer =
        [CChar](
            repeating: 0,
            count: 2_048
        )

    let result: Int32 =
        jsonBuffer
            .withUnsafeMutableBufferPointer {
                jsonPointer in

                errorBuffer
                    .withUnsafeMutableBufferPointer {
                        errorPointer in

                        loadReminderTagsJSON(
                            jsonPointer.baseAddress!,
                            Int32(
                                jsonPointer.count
                            ),
                            errorPointer.baseAddress!,
                            Int32(
                                errorPointer.count
                            )
                        )
                    }
            }

    guard result == 0 else {
        let message =
            errorBuffer
                .withUnsafeBufferPointer {
                    pointer -> String in

                    guard
                        let base =
                            pointer.baseAddress
                    else {
                        return ""
                    }

                    return String(
                        cString: base
                    )
                }

        stderr(
            "Could not load Reminders tags: \(message)"
        )

        return []
    }

    let json =
        jsonBuffer
            .withUnsafeBufferPointer {
                pointer -> String in

                guard
                    let base =
                        pointer.baseAddress
                else {
                    return "[]"
                }

                return String(
                    cString: base
                )
            }

    guard
        let data =
            json.data(
                using: .utf8
            ),
        let tags =
            try? JSONSerialization
                .jsonObject(
                    with: data
                ) as? [String]
    else {
        return []
    }

    return tags
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

func requestRemindersAccess() -> Bool {
    let semaphore = DispatchSemaphore(value: 0)

    var granted = false
    var accessError: Error?

    store.requestFullAccessToReminders { success, error in
        granted = success
        accessError = error
        semaphore.signal()
    }

    semaphore.wait()

    if let accessError {
        stderr(
            "Reminders permission error: " +
            accessError.localizedDescription
        )
    }

    return granted
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

func dueParts(
    from value: String?,
    time: String?
) -> (Int32, Int32, Int32, Int32, Int32, Int32) {

    guard let value, value != "none" else {
        return (0, 0, 0, 0, 0, 0)
    }

    let calendar = Calendar.current
    let date: Date?

    switch value {
    case "today":
        date = Date()

    case "tomorrow":
        date = calendar.date(
            byAdding: .day,
            value: 1,
            to: Date()
        )

    case "weekend":
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSaturday = (7 - weekday + 7) % 7

        date = calendar.date(
            byAdding: .day,
            value: daysUntilSaturday,
            to: today
        )

    case "nextweek":
        let today = calendar.startOfDay(for: Date())

        date = calendar.nextDate(
            after: today,
            matching: DateComponents(weekday: 2),
            matchingPolicy: .nextTime,
            direction: .forward
        )

    default:
        let parts = value.split(separator: "-")

        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return (0, 0, 0, 0, 0, 0)
        }

        var hour: Int32 = 0
        var minute: Int32 = 0
        var hasTime: Int32 = 0

        if let time, !time.isEmpty {
            let timeParts = time.split(separator: ":")

            if
                timeParts.count == 2,
                let h = Int(timeParts[0]),
                let m = Int(timeParts[1]),
                (0...23).contains(h),
                (0...59).contains(m)
            {
                hour = Int32(h)
                minute = Int32(m)
                hasTime = 1
            }
        }

        return (
            Int32(year),
            Int32(month),
            Int32(day),
            hour,
            minute,
            hasTime
        )
    }

    guard let date else {
        return (0, 0, 0, 0, 0, 0)
    }

    let components = calendar.dateComponents(
        [.year, .month, .day],
        from: date
    )

    var hour: Int32 = 0
    var minute: Int32 = 0
    var hasTime: Int32 = 0

    if let time, !time.isEmpty {
        let timeParts = time.split(separator: ":")

        if
            timeParts.count == 2,
            let h = Int(timeParts[0]),
            let m = Int(timeParts[1]),
            (0...23).contains(h),
            (0...59).contains(m)
        {
            hour = Int32(h)
            minute = Int32(m)
            hasTime = 1
        }
    }

    return (
        Int32(components.year ?? 0),
        Int32(components.month ?? 0),
        Int32(components.day ?? 0),
        hour,
        minute,
        hasTime
    )
}

func createReminderList(
    named rawName: String
) -> [String: Any] {

    let name = rawName.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard !name.isEmpty else {
        return [
            "ok": false,
            "error": "List name cannot be empty."
        ]
    }

    // Do not create a duplicate with different capitalization.
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

    let calendar =
        EKCalendar(
            for: .reminder,
            eventStore: store
        )

    calendar.title = name

    // Create it in the same account/source Apple normally uses
    // for new reminders.
    if let source =
        store.defaultCalendarForNewReminders()?.source
    {
        calendar.source = source

    } else if let source =
        store.calendars(for: .reminder).first?.source
    {
        calendar.source = source

    } else {
        return [
            "ok": false,
            "error": "Could not determine a Reminders account for the new list."
        ]
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
        return [
            "ok": false,
            "error": error.localizedDescription
        ]
    }
}

func createReminder(
    from request: [String: Any]
) -> [String: Any] {

    guard
        let rawTitle = request["title"] as? String
    else {
        return [
            "ok": false,
            "error": "Missing reminder title."
        ]
    }

    let title = rawTitle.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard !title.isEmpty else {
        return [
            "ok": false,
            "error": "Missing reminder title."
        ]
    }

    guard
        let listID = request["listId"] as? String,
        let list = store.calendars(for: .reminder)
            .first(where: {
                $0.calendarIdentifier == listID
            })
    else {
        return [
            "ok": false,
            "error": "Reminder list not found."
        ]
    }

    let url = request["url"] as? String ?? ""

    let imageURL =
        request["imageUrl"] as? String ?? ""
    let due = request["due"] as? String
    let time = request["time"] as? String

    let notes =
        request["notes"] as? String ?? ""

    let tags =
        request["tags"] as? [String] ?? []

    let tagsJSON: String

    if
        let data =
            try? JSONSerialization.data(
                withJSONObject: tags
            ),
        let encoded =
            String(
                data: data,
                encoding: .utf8
            )
    {
        tagsJSON = encoded
    } else {
        tagsJSON = "[]"
    }

    let requestedPriority =
        request["priority"] as? Int ?? 0

    let priority: Int32

    switch requestedPriority {
    case 1:
        priority = 1

    case 5:
        priority = 5

    case 9:
        priority = 9

    default:
        priority = 0
    }

    let (
        year,
        month,
        day,
        hour,
        minute,
        hasTime
    ) = dueParts(
        from: due,
        time: time
    )

    var recurrenceFrequency: Int32 = -1
    var recurrenceInterval: Int32 = 1
    var recurrenceJSON = ""

    if
        let recurrence =
            request["recurrence"]
                as? [String: Any],
        let frequency =
            recurrence["frequency"]
                as? String
    {
        switch frequency {
        case "daily":
            recurrenceFrequency = 0

        case "weekly":
            recurrenceFrequency = 1

        case "monthly":
            recurrenceFrequency = 2

        case "yearly":
            recurrenceFrequency = 3

        default:
            recurrenceFrequency = -1
        }

        if let interval =
            recurrence["interval"]
                as? Int
        {
            recurrenceInterval =
                Int32(
                    max(
                        1,
                        min(999, interval)
                    )
                )
        }

        if
            JSONSerialization
                .isValidJSONObject(recurrence),
            let data =
                try? JSONSerialization.data(
                    withJSONObject: recurrence
                ),
            let json =
                String(
                    data: data,
                    encoding: .utf8
                )
        {
            recurrenceJSON = json
        }
    }

    var errorBuffer = [CChar](
        repeating: 0,
        count: 2048
    )

    let result: Int32 =
        errorBuffer.withUnsafeMutableBufferPointer {
            errorPointer in

            listID.withCString {
                listPointer in

                title.withCString {
                    titlePointer in

                    url.withCString {
                        urlPointer in

                        imageURL.withCString {
                            imageURLPointer in

                            recurrenceJSON.withCString {
                                recurrencePointer in

                                notes.withCString {
                                    notesPointer in

                                    tagsJSON.withCString {
                                        tagsPointer in

                                        addRichReminder(
                                            listPointer,
                                            titlePointer,
                                            urlPointer,
                                            imageURLPointer,
                                            year,
                                            month,
                                            day,
                                            hour,
                                            minute,
                                            hasTime,
                                            recurrenceFrequency,
                                            recurrenceInterval,
                                            recurrencePointer,
                                            priority,
                                            notesPointer,
                                            tagsPointer,
                                            errorPointer.baseAddress!,
                                            Int32(
                                                errorPointer.count
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    guard result == 0 else {
        let message = String(cString: errorBuffer)

        return [
            "ok": false,
            "error":
                message.isEmpty
                    ? "Could not create reminder."
                    : message
        ]
    }

    return [
        "ok": true,
        "title": title,
        "list": list.title
    ]
}

guard requestRemindersAccess() else {
    stderr("Reminders access was denied.")
    exit(1)
}

while let request = readMessage() {

    guard let action = request["action"] as? String else {
        send([
            "ok": false,
            "error": "Missing action."
        ])
        continue
    }

    switch action {

    case "lists":
        send([
            "ok": true,
            "lists": reminderLists()
        ])

    case "tags":
        send([
            "ok": true,
            "tags": loadReminderTagNames()
        ])

    case "add":
        send(createReminder(from: request))

    case "createList":
        guard let name =
            request["name"] as? String
        else {
            send([
                "ok": false,
                "error": "Missing list name."
            ])
            continue
        }

        send(
            createReminderList(
                named: name
            )
        )

    default:
        send([
            "ok": false,
            "error": "Unknown action: \(action)"
        ])
    }
}
