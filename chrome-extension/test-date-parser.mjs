import assert from "node:assert/strict";
import { parseSmartDate } from "./date-parser.js";

const now = new Date(2026, 7, 22, 15, 0, 0);

const tests = [
  "Read this tomorrow",
  "Read this tmr",
  "Buy this weekend",
  "Check this next week",
  "Review in 3 days",
  "Come back to this in 2 weeks",
  "Do this next Monday",
  "Do this Friday"
];

for (const text of tests) {
  console.log("");
  console.log(text);
  console.log(parseSmartDate(text, now));
}


const stackedNow =
  new Date(
    2026,
    8,
    1,
    9,
    0,
    0
  );

const stackedText =
  "start oct 3 then nov 4";

const stacked =
  parseSmartDate(
    stackedText,
    stackedNow
  );

const stackedDateTokens =
  stacked.tokens.filter(
    token =>
      token.kind === "date"
  );

assert.equal(
  stacked.due,
  "2026-11-04",
  "right-most natural date must be active"
);

assert.deepEqual(
  stackedDateTokens.map(
    token =>
      token.text.toLowerCase()
  ),
  [
    "oct 3",
    "nov 4"
  ],
  "all natural date occurrences must remain recognized"
);

assert.deepEqual(
  stacked.highlightTokens
    .filter(
      token =>
        token.kind === "date"
    )
    .map(
      token =>
        token.text.toLowerCase()
    ),
  [
    "nov 4"
  ],
  "only active natural date must be highlighted"
);

const latestToken =
  stackedDateTokens[
    stackedDateTokens.length - 1
  ];

const afterRejectingLatest =
  parseSmartDate(
    stackedText,
    stackedNow,
    [{
      start: latestToken.start,
      end: latestToken.end
    }]
  );

assert.equal(
  afterRejectingLatest.due,
  "2026-10-03",
  "rejecting active date must reveal previous date"
);

assert.deepEqual(
  afterRejectingLatest
    .highlightTokens
    .filter(
      token =>
        token.kind === "date"
    )
    .map(
      token =>
        token.text.toLowerCase()
    ),
  [
    "oct 3"
  ],
  "fallback date must become highlighted"
);

const afterRejectingAll =
  parseSmartDate(
    stackedText,
    stackedNow,
    stackedDateTokens.map(
      token => ({
        start: token.start,
        end: token.end
      })
    )
  );

assert.equal(
  afterRejectingAll.due,
  null,
  "rejecting all dates must leave no smart due date"
);

const editedAfterRemoval =
  parseSmartDate(
    "start oct 3 then nov 5",
    stackedNow,
    [{
      start: stackedDateTokens[0].start,
      end: stackedDateTokens[0].end
    }]
  );

assert.equal(
  editedAfterRemoval.due,
  "2026-11-05",
  "edited date phrase must become eligible again"
);

assert.deepEqual(
  editedAfterRemoval
    .highlightTokens
    .filter(
      token =>
        token.kind === "date"
    )
    .map(
      token =>
        token.text.toLowerCase()
    ),
  [
    "nov 5"
  ],
  "edited date must be active and highlighted"
);

const capitalizedName =
  parseSmartDate(
    "Meet Tom Hanks today",
    stackedNow
  );

assert.equal(
  capitalizedName.due,
  "2026-09-01",
  "capitalized Tom must not override today"
);

console.log(
  "\\nStacked natural-date regression checks passed"
);
