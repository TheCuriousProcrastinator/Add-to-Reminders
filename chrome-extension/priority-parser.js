const PRIORITIES = {
  p1: {
    value: 1,
    label: "High"
  },

  p2: {
    value: 5,
    label: "Medium"
  },

  p3: {
    value: 9,
    label: "Low"
  },

  p4: {
    value: 0,
    label: "None"
  }
};

export function parseSmartPriority(text) {
  const regex =
    /(^|\s)(p[1-4])(?=$|\s|[.,!?;:])/gi;

  let best = null;
  let match;

  while (
    (match = regex.exec(text)) !== null
  ) {
    const token =
      match[2].toLowerCase();

    const priority =
      PRIORITIES[token];

    if (!priority) {
      continue;
    }

    const start =
      match.index +
      (match[1]?.length || 0);

    best = {
      matchedText: match[2],
      matchedStart: start,
      matchedEnd:
        start + match[2].length,

      value: priority.value,
      label: priority.label
    };
  }

  return best;
}
