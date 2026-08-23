const SELECTION_MENU =
  "add-selection-to-reminders";

async function setupMenus() {
  await chrome.contextMenus.removeAll();

  chrome.contextMenus.create({
    id: SELECTION_MENU,
    title: "Add selection to Reminders",
    contexts: ["selection"],
    documentUrlPatterns: [
      "http://*/*",
      "https://*/*"
    ]
  });
}

function normalizeSelectedText(text) {
  return text
    .replace(/\s+/g, " ")
    .trim();
}

function beginningChunk(text, maxLength = 90) {
  if (text.length <= maxLength) {
    return text;
  }

  const chunk =
    text.slice(0, maxLength);

  const lastSpace =
    chunk.lastIndexOf(" ");

  if (lastSpace > 40) {
    return chunk
      .slice(0, lastSpace)
      .trim();
  }

  return chunk.trim();
}

function endingChunk(text, maxLength = 90) {
  if (text.length <= maxLength) {
    return text;
  }

  const chunk =
    text.slice(-maxLength);

  const firstSpace =
    chunk.indexOf(" ");

  if (
    firstSpace >= 0 &&
    firstSpace < maxLength - 40
  ) {
    return chunk
      .slice(firstSpace + 1)
      .trim();
  }

  return chunk.trim();
}

function makeTextFragmentUrl(
  rawUrl,
  selectedText
) {
  const text =
    normalizeSelectedText(
      selectedText
    );

  if (!text) {
    return rawUrl;
  }

  const url =
    new URL(rawUrl);

  let existingFragment =
    url.hash
      .slice(1)
      .split(":~:")[0];

  const baseUrl =
    rawUrl.split("#")[0];

  let directive;

  if (text.length <= 180) {
    directive =
      "text=" +
      encodeURIComponent(text);

  } else {
    const start =
      beginningChunk(text);

    const end =
      endingChunk(text);

    directive =
      "text=" +
      encodeURIComponent(start) +
      "," +
      encodeURIComponent(end);
  }

  if (existingFragment) {
    return (
      baseUrl +
      "#" +
      existingFragment +
      ":~:" +
      directive
    );
  }

  return (
    baseUrl +
    "#:~:" +
    directive
  );
}

setupMenus().catch(console.error);

chrome.contextMenus.onClicked.addListener(
  async (info, tab) => {
    const pageUrl =
      info.pageUrl ||
      tab?.url ||
      "";

    if (
      !pageUrl.startsWith("http://") &&
      !pageUrl.startsWith("https://")
    ) {
      return;
    }

    if (
      info.menuItemId ===
      SELECTION_MENU
    ) {
      const selection =
        (info.selectionText || "")
          .trim();

      if (!selection) {
        return;
      }

      const deepUrl =
        makeTextFragmentUrl(
          pageUrl,
          selection
        );

      await chrome.storage.local.set({
        pendingReminderCapture: {
          title: selection,
          url: deepUrl,
          createdAt: Date.now()
        }
      });

    } else {
      return;
    }

    try {
      await chrome.action.openPopup();
    } catch (error) {
      console.error(
        "Could not open popup:",
        error
      );
    }
  }
);
