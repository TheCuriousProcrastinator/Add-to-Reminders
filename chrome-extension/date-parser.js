function startOfDay(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function addDays(date, amount) {
  const d = new Date(date);
  d.setDate(d.getDate() + amount);
  return d;
}

function addWeeks(date, amount) {
  return addDays(date, amount * 7);
}

function nextWeekday(date, targetDay, allowToday = false) {
  const d = startOfDay(date);
  const current = d.getDay();

  let delta = (targetDay - current + 7) % 7;

  if (delta === 0 && !allowToday) {
    delta = 7;
  }

  return addDays(d, delta);
}

function nextDayOfMonth(date, day) {
  const base = startOfDay(date);

  for (let offset = 0; offset < 24; offset++) {
    const candidate = new Date(
      base.getFullYear(),
      base.getMonth() + offset,
      day
    );

    // JS rolls invalid dates such as Feb 31 into March.
    if (candidate.getDate() !== day) {
      continue;
    }

    if (candidate >= base) {
      return candidate;
    }
  }

  return base;
}

function isoDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

function isoTime(date) {
  const hour = String(date.getHours()).padStart(2, "0");
  const minute = String(date.getMinutes()).padStart(2, "0");

  return `${hour}:${minute}`;
}

function setClock(baseDate, hour, minute) {
  if (
    !Number.isInteger(hour) ||
    !Number.isInteger(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  const result = new Date(baseDate);
  result.setHours(hour, minute, 0, 0);

  return result;
}

function parseTimeToken(token) {
  if (!token) return null;

  const value = token.trim().toLowerCase();

  if (value === "noon") {
    return { hour: 12, minute: 0 };
  }

  // 4pm / 4:30pm
  let match = value.match(
    /^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$/
  );

  if (match) {
    let hour = Number(match[1]);
    const minute = Number(match[2] || 0);

    if (
      hour < 1 ||
      hour > 12 ||
      minute > 59
    ) {
      return null;
    }

    if (
      match[3] === "pm" &&
      hour !== 12
    ) {
      hour += 12;
    }

    if (
      match[3] === "am" &&
      hour === 12
    ) {
      hour = 0;
    }

    return { hour, minute };
  }

  // 16:00
  match = value.match(
    /^([01]?\d|2[0-3]):([0-5]\d)$/
  );

  if (match) {
    return {
      hour: Number(match[1]),
      minute: Number(match[2])
    };
  }

  // 1600
  match = value.match(
    /^([01]\d|2[0-3])([0-5]\d)$/
  );

  if (match) {
    return {
      hour: Number(match[1]),
      minute: Number(match[2])
    };
  }

  return null;
}

function resultFor(
  text,
  match,
  date,
  includeTime = false,
  recurrence = null
) {
  return {
    original: text,

    title: (
      text.slice(0, match.index) +
      text.slice(
        match.index + match[0].length
      )
    )
      .replace(/\s+/g, " ")
      .trim(),

    matchedText: match[0],
    matchedStart: match.index,
    matchedEnd:
      match.index + match[0].length,

    due: isoDate(date),

    time:
      includeTime
        ? isoTime(date)
        : null,

    recurrence
  };
}

function emptyResult(text) {
  return {
    original: text,
    title: text.trim(),
    matchedText: null,
    matchedStart: null,
    matchedEnd: null,
    due: null,
    time: null,
    recurrence: null
  };
}

const WEEKDAYS = {
  sunday: 0,
  sun: 0,

  monday: 1,
  mon: 1,

  tuesday: 2,
  tue: 2,
  tues: 2,

  wednesday: 3,
  wed: 3,

  thursday: 4,
  thu: 4,
  thur: 4,
  thurs: 4,

  friday: 5,
  fri: 5,

  saturday: 6,
  sat: 6
};

const WEEKDAY_PATTERN =
  "sunday|sun|monday|mon|tuesday|tue|tues|" +
  "wednesday|wed|thursday|thu|thur|thurs|" +
  "friday|fri|saturday|sat";

const TIME =
  String.raw`(?:noon|\d{1,2}(?::\d{2})?\s*(?:am|pm)|(?:[01]?\d|2[0-3]):[0-5]\d|(?:[01]\d|2[0-3])[0-5]\d)`;

// QUICKADD_PARITY_V018

const ONE_TIME_ORDINALS = {
  "1st": 1,
  first: 1,
  "2nd": 2,
  second: 2,
  "3rd": 3,
  third: 3,
  "4th": 4,
  fourth: 4,
  "5th": 5,
  fifth: 5,
  last: -1
};

const ONE_TIME_ORDINAL_PATTERN =
  "1st|first|2nd|second|3rd|third|" +
  "4th|fourth|5th|fifth|last";

const MONTHS = {
  january: 0,
  jan: 0,
  february: 1,
  feb: 1,
  march: 2,
  mar: 2,
  april: 3,
  apr: 3,
  may: 4,
  june: 5,
  jun: 5,
  july: 6,
  jul: 6,
  august: 7,
  aug: 7,
  september: 8,
  sept: 8,
  sep: 8,
  october: 9,
  oct: 9,
  november: 10,
  nov: 10,
  december: 11,
  dec: 11
};

const MONTH_PATTERN =
  "january|jan|february|feb|march|mar|" +
  "april|apr|may|june|jun|july|jul|" +
  "august|aug|september|sept|sep|" +
  "october|oct|november|nov|december|dec";

function recurrence(
  frequency,
  interval,
  label,
  extra = {}
) {
  return {
    frequency,
    interval,
    label,
    ...extra
  };
}

function recurrenceDateWithTime(
  base,
  timeToken
) {
  const parsed = parseTimeToken(timeToken);

  if (!parsed) {
    return {
      date: base,
      includeTime: false
    };
  }

  return {
    date:
      setClock(
        base,
        parsed.hour,
        parsed.minute
      ),
    includeTime: true
  };
}

function eventKitWeekday(jsDay) {
  // JS: Sunday 0 ... Saturday 6
  // EventKit: Sunday 1 ... Saturday 7
  return jsDay + 1;
}

function fullWeekdayName(jsDay) {
  return [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
  ][jsDay];
}

function nextMatchingWeekday(date, weekdays) {
  const base = startOfDay(date);

  for (let offset = 0; offset <= 7; offset++) {
    const candidate = addDays(base, offset);

    if (weekdays.includes(candidate.getDay())) {
      return candidate;
    }
  }

  return base;
}

function nthWeekdayDate(date, weekday, weekNumber) {
  const base = startOfDay(date);

  for (let offset = 0; offset < 24; offset++) {
    const monthStart = new Date(
      base.getFullYear(),
      base.getMonth() + offset,
      1
    );

    let candidate;

    if (weekNumber > 0) {
      const delta =
        (weekday - monthStart.getDay() + 7) % 7;

      const day =
        1 +
        delta +
        ((weekNumber - 1) * 7);

      candidate = new Date(
        monthStart.getFullYear(),
        monthStart.getMonth(),
        day
      );

      if (
        candidate.getMonth() !==
        monthStart.getMonth()
      ) {
        continue;
      }

    } else {
      const lastDay = new Date(
        monthStart.getFullYear(),
        monthStart.getMonth() + 1,
        0
      );

      const delta =
        (lastDay.getDay() - weekday + 7) % 7;

      candidate = new Date(
        lastDay.getFullYear(),
        lastDay.getMonth(),
        lastDay.getDate() - delta
      );
    }

    if (candidate >= base) {
      return candidate;
    }
  }

  return base;
}

function addMonthsClamped(date, amount) {
  const source = new Date(date);
  const originalDay = source.getDate();

  const targetMonth = new Date(
    source.getFullYear(),
    source.getMonth() + amount,
    1,
    source.getHours(),
    source.getMinutes(),
    source.getSeconds(),
    source.getMilliseconds()
  );

  const lastDay = new Date(
    targetMonth.getFullYear(),
    targetMonth.getMonth() + 1,
    0
  ).getDate();

  targetMonth.setDate(
    Math.min(originalDay, lastDay)
  );

  return targetMonth;
}

function ordinalWeekdayDateInMonth(
  year,
  month,
  weekday,
  weekNumber
) {
  const monthStart = new Date(
    year,
    month,
    1
  );

  let candidate;

  if (weekNumber === -1) {
    const lastDay = new Date(
      year,
      month + 1,
      0
    );

    const offset =
      (
        lastDay.getDay() -
        weekday +
        7
      ) % 7;

    candidate = new Date(
      year,
      month,
      lastDay.getDate() - offset
    );
  } else {
    const firstWeekday =
      monthStart.getDay();

    const day =
      1 +
      (
        weekday -
        firstWeekday +
        7
      ) % 7 +
      (
        weekNumber - 1
      ) * 7;

    candidate = new Date(
      year,
      month,
      day
    );
  }

  if (
    candidate.getFullYear() !== year ||
    candidate.getMonth() !== month
  ) {
    return null;
  }

  return startOfDay(candidate);
}

function resolveOrdinalWeekdayOfMonth(
  now,
  weekday,
  weekNumber,
  month,
  year = null
) {
  const today = startOfDay(now);

  if (Number.isInteger(year)) {
    return ordinalWeekdayDateInMonth(
      year,
      month,
      weekday,
      weekNumber
    );
  }

  const currentYear =
    today.getFullYear();

  for (
    let candidateYear = currentYear;
    candidateYear <= currentYear + 20;
    candidateYear++
  ) {
    const candidate =
      ordinalWeekdayDateInMonth(
        candidateYear,
        month,
        weekday,
        weekNumber
      );

    if (
      candidate &&
      candidate >= today
    ) {
      return candidate;
    }
  }

  return null;
}

function parseSmartDateSingle(
  text,
  now = new Date()
) {
  const every = String.raw`(?:every|ev)`;

  // QuickAdd parity: in 20 minutes / in 2 hours /
  // in 3 days at 4pm / in a week at noon
  {
    const regex = new RegExp(
      String.raw`\bin\s+(?:(a)|(\d+))\s+(minutes?|mins?|hours?|hrs?|days?|weeks?|months?)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const amount =
        match[1]
          ? 1
          : Number(match[2]);

      if (
        Number.isInteger(amount) &&
        amount > 0
      ) {
        const unit =
          match[3].toLowerCase();

        const parsedTime =
          parseTimeToken(match[4]);

        const isTimedUnit =
          unit.startsWith("min") ||
          unit.startsWith("hour") ||
          unit.startsWith("hr");

        let base;

        if (unit.startsWith("min")) {
          base = new Date(now);
          base.setMinutes(
            base.getMinutes() + amount
          );
        } else if (
          unit.startsWith("hour") ||
          unit.startsWith("hr")
        ) {
          base = new Date(now);
          base.setHours(
            base.getHours() + amount
          );
        } else {
          base = startOfDay(now);

          if (unit.startsWith("day")) {
            base.setDate(
              base.getDate() + amount
            );
          } else if (
            unit.startsWith("week")
          ) {
            base.setDate(
              base.getDate() + (amount * 7)
            );
          } else {
            base =
              addMonthsClamped(
                base,
                amount
              );
          }
        }

        const date =
          parsedTime
            ? setClock(
                base,
                parsedTime.hour,
                parsedTime.minute
              )
            : base;

        return resultFor(
          text,
          match,
          date,
          isTimedUnit || Boolean(parsedTime)
        );
      }
    }
  }


  // ---------------------------------
  // RECURRENCE
  // ---------------------------------

  // every weekday / every workday
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+(?:weekdays?|workdays?)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const jsDays = [1, 2, 3, 4, 5];

      const base =
        nextMatchingWeekday(
          now,
          jsDays
        );

      const timed =
        recurrenceDateWithTime(
          base,
          match[1]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          "weekly",
          1,
          "Every weekday",
          {
            weekdays:
              jsDays.map(eventKitWeekday)
          }
        )
      );
    }
  }

  // every weekend
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+weekends?(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const jsDays = [6, 0];

      const base =
        nextMatchingWeekday(
          now,
          jsDays
        );

      const timed =
        recurrenceDateWithTime(
          base,
          match[1]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          "weekly",
          1,
          "Every weekend",
          {
            weekdays:
              jsDays.map(eventKitWeekday)
          }
        )
      );
    }
  }

  // every mon, fri
  // ev mon, wed, fri 3pm
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+((?:${WEEKDAY_PATTERN})(?:\s*,\s*(?:${WEEKDAY_PATTERN}))+)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const tokens =
        match[1]
          .split(",")
          .map(value => value.trim().toLowerCase());

      const jsDays = [
        ...new Set(
          tokens.map(
            token => WEEKDAYS[token]
          )
        )
      ];

      if (
        jsDays.length >= 2 &&
        jsDays.every(Number.isInteger)
      ) {
        const base =
          nextMatchingWeekday(
            now,
            jsDays
          );

        const timed =
          recurrenceDateWithTime(
            base,
            match[2]
          );

        const names =
          jsDays.map(fullWeekdayName);

        return resultFor(
          text,
          match,
          timed.date,
          timed.includeTime,
          recurrence(
            "weekly",
            1,
            `Every ${names.join(", ")}`,
            {
              weekdays:
                jsDays.map(eventKitWeekday)
            }
          )
        );
      }
    }
  }

  // every 3rd Friday
  // every third Friday
  // every last Friday
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+(1st|2nd|3rd|4th|5th|first|second|third|fourth|fifth|last)\s+(${WEEKDAY_PATTERN})(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const ordinal =
        match[1].toLowerCase();

      const weekNumbers = {
        "1st": 1,
        first: 1,
        "2nd": 2,
        second: 2,
        "3rd": 3,
        third: 3,
        "4th": 4,
        fourth: 4,
        "5th": 5,
        fifth: 5,
        last: -1
      };

      const weekNumber =
        weekNumbers[ordinal];

      const jsDay =
        WEEKDAYS[
          match[2].toLowerCase()
        ];

      const base =
        nthWeekdayDate(
          now,
          jsDay,
          weekNumber
        );

      const timed =
        recurrenceDateWithTime(
          base,
          match[3]
        );

      const displayOrdinal =
        weekNumber === -1
          ? "last"
          : (
              ["", "1st", "2nd", "3rd", "4th", "5th"][
                weekNumber
              ]
            );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          "monthly",
          1,
          `Every ${displayOrdinal} ${fullWeekdayName(jsDay)}`,
          {
            weekdays: [
              {
                day:
                  eventKitWeekday(jsDay),
                weekNumber
              }
            ]
          }
        )
      );
    }
  }

  // every other Monday / every other Friday 3pm
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+other\s+(${WEEKDAY_PATTERN})(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const weekday =
        WEEKDAYS[
          match[1].toLowerCase()
        ];

      const base =
        nextWeekday(
          now,
          weekday,
          true
        );

      const timed =
        recurrenceDateWithTime(
          base,
          match[2]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          "weekly",
          2,
          `Every other ${match[1]}`
        )
      );
    }
  }

  // every Monday / every Fri at 16:00
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+(${WEEKDAY_PATTERN})(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const weekday =
        WEEKDAYS[
          match[1].toLowerCase()
        ];

      const base =
        nextWeekday(
          now,
          weekday,
          true
        );

      const timed =
        recurrenceDateWithTime(
          base,
          match[2]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          "weekly",
          1,
          `Every ${match[1]}`
        )
      );
    }
  }

  // every 3 days / every 2 weeks / every 4 months / every 2 years
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+(\d+)\s+(days?|weeks?|months?|years?)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const interval =
        Number(match[1]);

      if (
        interval >= 1 &&
        interval <= 999
      ) {
        const unit =
          match[2].toLowerCase();

        let frequency;

        if (unit.startsWith("day")) {
          frequency = "daily";
        } else if (
          unit.startsWith("week")
        ) {
          frequency = "weekly";
        } else if (
          unit.startsWith("month")
        ) {
          frequency = "monthly";
        } else {
          frequency = "yearly";
        }

        const timed =
          recurrenceDateWithTime(
            startOfDay(now),
            match[3]
          );

        return resultFor(
          text,
          match,
          timed.date,
          timed.includeTime,
          recurrence(
            frequency,
            interval,
            `Every ${interval} ${match[2]}`
          )
        );
      }
    }
  }

  // every other day/week/month/year
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+other\s+(day|week|month|year)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const unit =
        match[1].toLowerCase();

      const frequency = {
        day: "daily",
        week: "weekly",
        month: "monthly",
        year: "yearly"
      }[unit];

      const timed =
        recurrenceDateWithTime(
          startOfDay(now),
          match[2]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          frequency,
          2,
          `Every other ${unit}`
        )
      );
    }
  }

  // every day/week/month/year
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+(day|week|month|year)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const unit =
        match[1].toLowerCase();

      const frequency = {
        day: "daily",
        week: "weekly",
        month: "monthly",
        year: "yearly"
      }[unit];

      const timed =
        recurrenceDateWithTime(
          startOfDay(now),
          match[2]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          frequency,
          1,
          `Every ${unit}`
        )
      );
    }
  }

  // daily / weekly / monthly / yearly
  {
    const regex = new RegExp(
      String.raw`\b(daily|weekly|monthly|yearly)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const map = {
        daily: "daily",
        weekly: "weekly",
        monthly: "monthly",
        yearly: "yearly"
      };

      const frequency =
        map[
          match[1].toLowerCase()
        ];

      const timed =
        recurrenceDateWithTime(
          startOfDay(now),
          match[2]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          frequency,
          1,
          match[1]
        )
      );
    }
  }

  // quarterly / every quarter
  {
    const regex =
      /\b(?:quarterly|(?:every|ev)\s+quarter)(?:\s+(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm)|(?:[01]?\d|2[0-3]):[0-5]\d|(?:[01]\d|2[0-3])[0-5]\d))?\b/i;

    const match = text.match(regex);

    if (match) {
      const timed =
        recurrenceDateWithTime(
          startOfDay(now),
          match[1]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime,
        recurrence(
          "monthly",
          3,
          "Every quarter"
        )
      );
    }
  }

  // every 27th / every 1st
  {
    const regex = new RegExp(
      String.raw`\b${every}\s+(\d{1,2})(?:st|nd|rd|th)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const day =
        Number(match[1]);

      if (day >= 1 && day <= 31) {
        const base =
          nextDayOfMonth(
            now,
            day
          );

        const timed =
          recurrenceDateWithTime(
            base,
            match[2]
          );

        return resultFor(
          text,
          match,
          timed.date,
          timed.includeTime,
          recurrence(
            "monthly",
            1,
            `Every ${match[1]}th`
          )
        );
      }
    }
  }

  // ---------------------------------
  // ONE-TIME SMART DATES
  // ---------------------------------

  // QuickAdd parity:
  // 3rd Friday of September
  // the last Monday in November
  // on the 2nd Tuesday of Sep 2027 at 4pm

  {
    const regex = new RegExp(
      String.raw`\b(?:(?:on\s+)?the\s+|on\s+)?(${ONE_TIME_ORDINAL_PATTERN})\s+(${WEEKDAY_PATTERN})\s+(?:of|in)\s+(${MONTH_PATTERN})(?:\s*,?\s*(\d{4}))?(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const weekNumber =
        ONE_TIME_ORDINALS[
          match[1].toLowerCase()
        ];

      const weekday =
        WEEKDAYS[
          match[2].toLowerCase()
        ];

      const month =
        MONTHS[
          match[3].toLowerCase()
        ];

      const year =
        match[4]
          ? Number(match[4])
          : null;

      const base =
        resolveOrdinalWeekdayOfMonth(
          now,
          weekday,
          weekNumber,
          month,
          year
        );

      if (base) {
        const timed =
          recurrenceDateWithTime(
            base,
            match[5]
          );

        return resultFor(
          text,
          match,
          timed.date,
          timed.includeTime
        );
      }
    }
  }

  // QuickAdd parity:
  // tonight
  // tonight at 8pm
  // next month
  // next month at noon

  {
    const regex = new RegExp(
      String.raw`\b(tonight|next\s+month)(?:\s+(?:at\s+)?(${TIME}))?\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const token =
        match[1].toLowerCase();

      const base =
        token === "tonight"
          ? startOfDay(now)
          : addMonthsClamped(
              startOfDay(now),
              1
            );

      const timed =
        recurrenceDateWithTime(
          base,
          match[2]
        );

      return resultFor(
        text,
        match,
        timed.date,
        timed.includeTime
      );
    }
  }

  // in 30 minutes / in 2 hours
  {
    const match = text.match(
      /\bin\s+(\d+)\s+(minutes?|mins?|hours?|hrs?)\b/i
    );

    if (match) {
      const amount =
        Number(match[1]);

      const unit =
        match[2].toLowerCase();

      const milliseconds =
        unit.startsWith("h")
          ? amount * 60 * 60 * 1000
          : amount * 60 * 1000;

      const target =
        new Date(
          now.getTime() +
          milliseconds
        );

      return resultFor(
        text,
        match,
        target,
        true
      );
    }
  }

  // today/tomorrow + time
  {
    const regex = new RegExp(
      String.raw`\b(today|tod|tomorrow|tom|tmr)\s+(?:at\s+)?(${TIME})\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      let base =
        startOfDay(now);

      if (
        /tomorrow|tom|tmr/i.test(
          match[1]
        )
      ) {
        base =
          addDays(base, 1);
      }

      const parsed =
        parseTimeToken(
          match[2]
        );

      if (parsed) {
        return resultFor(
          text,
          match,
          setClock(
            base,
            parsed.hour,
            parsed.minute
          ),
          true
        );
      }
    }
  }

  // next Monday + time
  {
    const regex = new RegExp(
      String.raw`\bnext\s+(${WEEKDAY_PATTERN})\s+(?:at\s+)?(${TIME})\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const base =
        nextWeekday(
          now,
          WEEKDAYS[
            match[1].toLowerCase()
          ]
        );

      const parsed =
        parseTimeToken(
          match[2]
        );

      if (parsed) {
        return resultFor(
          text,
          match,
          setClock(
            base,
            parsed.hour,
            parsed.minute
          ),
          true
        );
      }
    }
  }

  // Friday + time
  {
    const regex = new RegExp(
      String.raw`\b(${WEEKDAY_PATTERN})\s+(?:at\s+)?(${TIME})\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const base =
        nextWeekday(
          now,
          WEEKDAYS[
            match[1].toLowerCase()
          ],
          true
        );

      const parsed =
        parseTimeToken(
          match[2]
        );

      if (parsed) {
        return resultFor(
          text,
          match,
          setClock(
            base,
            parsed.hour,
            parsed.minute
          ),
          true
        );
      }
    }
  }

  // at 3pm / at 16:00
  {
    const regex = new RegExp(
      String.raw`\bat\s+(${TIME})\b`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const parsed =
        parseTimeToken(
          match[1]
        );

      if (parsed) {
        return resultFor(
          text,
          match,
          setClock(
            startOfDay(now),
            parsed.hour,
            parsed.minute
          ),
          true
        );
      }
    }
  }

  // bare time at end
  {
    const regex = new RegExp(
      String.raw`\b(${TIME})\s*$`,
      "i"
    );

    const match = text.match(regex);

    if (match) {
      const parsed =
        parseTimeToken(
          match[1]
        );

      if (parsed) {
        return resultFor(
          text,
          match,
          setClock(
            startOfDay(now),
            parsed.hour,
            parsed.minute
          ),
          true
        );
      }
    }
  }

  const patterns = [
    {
      regex:
        /\b(?:tomorrow|tom|tmr)\b/i,

      resolve:
        () =>
          addDays(
            startOfDay(now),
            1
          )
    },

    {
      regex:
        /\b(?:today|tod)\b/i,

      resolve:
        () =>
          startOfDay(now)
    },

    {
      regex:
        /\b(?:this\s+)?weekend\b/i,

      resolve:
        () =>
          nextWeekday(
            now,
            6,
            true
          )
    },

    {
      regex:
        /\bnext weekend\b/i,

      resolve:
        () => {
          const saturday =
            nextWeekday(
              now,
              6,
              false
            );

          return addDays(
            saturday,
            7
          );
        }
    },

    {
      regex:
        /\bnext week\b/i,

      resolve:
        () =>
          nextWeekday(
            now,
            1,
            false
          )
    },

    {
      regex:
        /\bin\s+(\d+)\s+days?\b/i,

      resolve:
        match =>
          addDays(
            startOfDay(now),
            Number(match[1])
          )
    },

    {
      regex:
        /\bin\s+(\d+)\s+weeks?\b/i,

      resolve:
        match =>
          addWeeks(
            startOfDay(now),
            Number(match[1])
          )
    },

    {
      regex:
        new RegExp(
          String.raw`\bnext\s+(${WEEKDAY_PATTERN})\b`,
          "i"
        ),

      resolve:
        match =>
          nextWeekday(
            now,
            WEEKDAYS[
              match[1].toLowerCase()
            ]
          )
    },

    {
      regex:
        new RegExp(
          String.raw`\b(${WEEKDAY_PATTERN})\b`,
          "i"
        ),

      resolve:
        match =>
          nextWeekday(
            now,
            WEEKDAYS[
              match[1].toLowerCase()
            ],
            true
          )
    }
  ];

  for (const pattern of patterns) {
    const match =
      text.match(
        pattern.regex
      );

    if (match) {
      return resultFor(
        text,
        match,
        pattern.resolve(match)
      );
    }
  }


  // QuickAdd parity: at 3pm / 15:00 / 1600 / noon
  // Also recognizes a time token at the end of the title.
  {
    const explicitRegex = new RegExp(
      String.raw`\bat\s+(${TIME})\b`,
      "i"
    );

    const terminalRegex = new RegExp(
      String.raw`\b(${TIME})\s*$`,
      "i"
    );

    const match =
      text.match(explicitRegex) ||
      text.match(terminalRegex);

    if (match) {
      const parsed =
        parseTimeToken(match[1]);

      if (parsed) {
        const date =
          setClock(
            now,
            parsed.hour,
            parsed.minute
          );

        return resultFor(
          text,
          match,
          date,
          true
        );
      }
    }
  }

  return emptyResult(text);
}


// MULTI-TOKEN SMART DATE WRAPPER

function smartRangesOverlap(a, b) {
  return (
    a.start < b.end &&
    b.start < a.end
  );
}

function maskSmartRanges(text, ranges = []) {
  let result = text;

  const valid = ranges
    .filter(range =>
      Number.isInteger(range?.start) &&
      Number.isInteger(range?.end) &&
      range.start >= 0 &&
      range.end > range.start &&
      range.end <= text.length
    )
    .sort((a, b) => b.start - a.start);

  for (const range of valid) {
    result =
      result.slice(0, range.start) +
      " ".repeat(range.end - range.start) +
      result.slice(range.end);
  }

  return result;
}

function isSmartTimeOnlyResult(result) {
  if (
    !result?.matchedText ||
    result.recurrence
  ) {
    return false;
  }

  const regex = new RegExp(
    String.raw`^(?:at\s+)?(?:${TIME})$`,
    "i"
  );

  return regex.test(
    result.matchedText.trim()
  );
}

function strongSmartDateExists(text) {
  const regex = new RegExp(
    String.raw`\b(?:today|tomorrow|tonight|next\s+(?:weekend|week|month|${WEEKDAY_PATTERN})|(?:this\s+)?weekend|${WEEKDAY_PATTERN}|in\s+(?:a|\d+)\s+(?:minutes?|mins?|hours?|hrs?|days?|weeks?|months?))\b`,
    "i"
  );

  return regex.test(text);
}

function shortAliasInsideResult(result, text) {
  if (
    result?.matchedStart == null ||
    result?.matchedEnd == null
  ) {
    return null;
  }

  const matched =
    text.slice(
      result.matchedStart,
      result.matchedEnd
    );

  const alias =
    /\b(?:tod|tom|tmr)\b/i.exec(matched);

  if (!alias) {
    return null;
  }

  const start =
    result.matchedStart +
    alias.index;

  return {
    start,
    end: start + alias[0].length,
    text: text.slice(
      start,
      start + alias[0].length
    )
  };
}

function preferredSmartDateResult(
  text,
  now,
  excludedRanges
) {
  let working =
    maskSmartRanges(
      text,
      excludedRanges
    );

  for (let attempt = 0; attempt < 12; attempt++) {
    const result =
      parseSmartDateSingle(
        working,
        now
      );

    if (
      !result?.matchedText ||
      result.recurrence ||
      isSmartTimeOnlyResult(result)
    ) {
      return result;
    }

    const alias =
      shortAliasInsideResult(
        result,
        working
      );

    if (!alias) {
      return result;
    }

    const originalAlias =
      text.slice(
        alias.start,
        alias.end
      );

    const capitalizedAlias =
      originalAlias !==
      originalAlias.toLowerCase();

    const strongerDate =
      strongSmartDateExists(
        working
      );

    if (
      !capitalizedAlias &&
      !strongerDate
    ) {
      return result;
    }

    working =
      maskSmartRanges(
        working,
        [alias]
      );
  }

  return emptyResult(text);
}

function independentSmartTime(
  text,
  now,
  excludedRanges
) {
  const masked =
    maskSmartRanges(
      text,
      excludedRanges
    );

  const regex = new RegExp(
    String.raw`\b(?:at\s+)?(${TIME})\b`,
    "ig"
  );

  let match;

  while (
    (match = regex.exec(masked)) !== null
  ) {
    const tokenStart = match.index;
    const tokenEnd =
      tokenStart +
      match[0].length;

    const before =
      text[tokenStart - 1] || "";

    const after =
      text[tokenEnd] || "";

    if (
      before === "/" ||
      before === "-" ||
      after === "/" ||
      after === "-"
    ) {
      continue;
    }

    const parsed =
      parseTimeToken(
        match[1]
      );

    if (!parsed) {
      continue;
    }

    const date =
      setClock(
        now,
        parsed.hour,
        parsed.minute
      );

    if (!date) {
      continue;
    }

    return {
      kind: "time",
      start: tokenStart,
      end: tokenEnd,
      text:
        text.slice(
          tokenStart,
          tokenEnd
        ),
      due: isoDate(date),
      time: isoTime(date)
    };
  }

  return null;
}

function removeSmartTokenRanges(
  text,
  tokens
) {
  let result = text;

  const sorted = [...tokens]
    .sort(
      (a, b) =>
        b.start - a.start
    );

  for (const token of sorted) {
    result =
      result.slice(0, token.start) +
      result.slice(token.end);
  }

  return result
    .replace(/\s+/g, " ")
    .trim();
}

export function parseSmartDate(
  text,
  now = new Date(),
  excludedRanges = []
) {
  const primary =
    preferredSmartDateResult(
      text,
      now,
      excludedRanges
    );

  let dateResult = primary;

  if (
    dateResult?.matchedText &&
    isSmartTimeOnlyResult(dateResult)
  ) {
    dateResult = null;
  }

  const blockedRanges = [
    ...excludedRanges
  ];

  if (
    dateResult?.matchedStart != null &&
    dateResult?.matchedEnd != null
  ) {
    blockedRanges.push({
      start: dateResult.matchedStart,
      end: dateResult.matchedEnd
    });
  }

  let timeResult = null;

  if (!dateResult?.time) {
    timeResult =
      independentSmartTime(
        text,
        now,
        blockedRanges
      );
  }

  const tokens = [];

  if (
    dateResult?.matchedStart != null &&
    dateResult?.matchedEnd != null
  ) {
    tokens.push({
      kind:
        dateResult.recurrence
          ? "recurrence"
          : "date",
      start: dateResult.matchedStart,
      end: dateResult.matchedEnd,
      text:
        text.slice(
          dateResult.matchedStart,
          dateResult.matchedEnd
        )
    });
  }

  if (timeResult) {
    tokens.push({
      kind: "time",
      start: timeResult.start,
      end: timeResult.end,
      text: timeResult.text
    });
  }

  tokens.sort(
    (a, b) =>
      a.start - b.start
  );

  const firstToken =
    tokens[0] || null;

  const due =
    dateResult?.due ||
    timeResult?.due ||
    null;

  const time =
    dateResult?.time ||
    timeResult?.time ||
    null;

  return {
    original: text,

    title:
      removeSmartTokenRanges(
        text,
        tokens
      ),

    matchedText:
      firstToken?.text || null,

    matchedStart:
      firstToken?.start ?? null,

    matchedEnd:
      firstToken?.end ?? null,

    due,
    time,

    recurrence:
      dateResult?.recurrence ||
      null,

    tokens
  };
}
