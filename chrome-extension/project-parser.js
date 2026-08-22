function escapeRegExp(value) {
  return value.replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&"
  );
}

export function parseSmartProject(
  text,
  lists = []
) {
  let best = null;

  for (const list of lists) {
    if (!list?.title || !list?.id) {
      continue;
    }

    const escaped =
      escapeRegExp(list.title);

    const regex =
      new RegExp(
        `(^|\\s)(/${escaped})(?=$|\\s|[.,!?;:])`,
        "gi"
      );

    let match;

    while (
      (match = regex.exec(text)) !== null
    ) {
      const prefix =
        match[1] || "";

      const start =
        match.index + prefix.length;

      const end =
        start + match[2].length;

      if (
        !best ||
        start > best.matchedStart
      ) {
        best = {
          listId: list.id,
          listTitle: list.title,
          matchedText: match[2],
          matchedStart: start,
          matchedEnd: end
        };
      }
    }
  }

  return best;
}

export function findProjectFragment(
  text,
  caret
) {
  const before =
    text.slice(0, caret);

  const slash =
    before.lastIndexOf("/");

  if (slash < 0) {
    return null;
  }

  // Only treat / as a list command if it begins
  // the title or follows whitespace.
  // This avoids triggering on things like Mac/Windows.
  if (
    slash > 0 &&
    !/\s/.test(before[slash - 1])
  ) {
    return null;
  }

  const query =
    before.slice(slash + 1);

  if (
    query.includes("/") ||
    query.includes("\n") ||
    query.length > 80
  ) {
    return null;
  }

  return {
    start: slash,
    end: caret,
    query
  };
}

export function filterProjectSuggestions(
  fragment,
  lists = []
) {
  if (!fragment) {
    return [];
  }

  const query =
    fragment.query
      .trim()
      .toLowerCase();

  const starts = [];
  const contains = [];

  for (const list of lists) {
    const name =
      list.title.toLowerCase();

    if (
      !query ||
      name.startsWith(query)
    ) {
      starts.push(list);

    } else if (
      name.includes(query)
    ) {
      contains.push(list);
    }
  }

  return [
    ...starts,
    ...contains
  ].slice(0, 7);
}
