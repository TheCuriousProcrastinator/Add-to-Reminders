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
