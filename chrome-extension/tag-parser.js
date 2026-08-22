export function parseSmartTags(text) {
  const regex =
    /(^|\s)#([\p{L}\p{N}][\p{L}\p{N}_-]*)(?=$|\s|[.,!?;:])/gu;

  const matches = [];
  const tags = [];
  const seen = new Set();

  let match;

  while (
    (match = regex.exec(text)) !== null
  ) {
    const prefix =
      match[1] || "";

    const start =
      match.index +
      prefix.length;

    const matchedText =
      `#${match[2]}`;

    const tag =
      match[2];

    matches.push({
      tag,
      matchedText,
      matchedStart: start,
      matchedEnd:
        start + matchedText.length
    });

    const key =
      tag.toLocaleLowerCase();

    if (!seen.has(key)) {
      seen.add(key);
      tags.push(tag);
    }
  }

  return {
    tags,
    matches
  };
}

export function findTagFragment(
  text,
  caret
) {
  const before =
    text.slice(0, caret);

  const hash =
    before.lastIndexOf("#");

  if (hash < 0) {
    return null;
  }

  // # must begin a token.
  if (
    hash > 0 &&
    !/\s/.test(before[hash - 1])
  ) {
    return null;
  }

  const query =
    before.slice(hash + 1);

  // Tags in our syntax are one token.
  if (
    /\s/.test(query) ||
    query.includes("#") ||
    query.length > 80
  ) {
    return null;
  }

  if (
    query &&
    !/^[\p{L}\p{N}_-]*$/u.test(query)
  ) {
    return null;
  }

  return {
    start: hash,
    end: caret,
    query
  };
}

export function filterTagSuggestions(
  fragment,
  tags = []
) {
  if (!fragment) {
    return [];
  }

  const query =
    fragment.query
      .trim()
      .toLocaleLowerCase();

  const starts = [];
  const contains = [];

  for (const tag of tags) {
    const name =
      String(tag).trim();

    if (!name) {
      continue;
    }

    const lower =
      name.toLocaleLowerCase();

    if (!query || lower.startsWith(query)) {
      starts.push(name);

    } else if (lower.includes(query)) {
      contains.push(name);
    }
  }

  return [
    ...starts,
    ...contains
  ].slice(0, 7);
}
