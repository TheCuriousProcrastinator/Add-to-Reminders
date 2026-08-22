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
  String.raw`(?:\d{1,2}(?::\d{2})?\s*(?:am|pm)|(?:[01]?\d|2[0-3]):[0-5]\d|(?:[01]\d|2[0-3])[0-5]\d)`;

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

function reminderKitWeekday(jsDay) {
  // JS: Sunday 0 ... Saturday 6
  // ReminderKit: Sunday 1 ... Saturday 7
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

export function parseSmartDate(
  text,
  now = new Date()
) {
  const every = String.raw`(?:every|ev)`;

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
              jsDays.map(reminderKitWeekday)
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
              jsDays.map(reminderKitWeekday)
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
                jsDays.map(reminderKitWeekday)
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
                  reminderKitWeekday(jsDay),
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

  return emptyResult(text);
}
