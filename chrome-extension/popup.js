import { parseSmartDate } from "./date-parser.js";

import {
  parseSmartProject,
  findProjectFragment,
  filterProjectSuggestions
} from "./project-parser.js";

import {
  parseSmartPriority
} from "./priority-parser.js";


let rejectedSmartDateRanges = [];
let activeSmartDateTokens = [];
let lastSmartDateText = "";


const HOST_NAME = "com.alex.addtoreminders";

const form = document.getElementById("form");
const titleInput = document.getElementById("title");
const titleMirror = document.getElementById("titleMirror");
const urlElement = document.getElementById("url");
const projectSuggestions =
  document.getElementById("projectSuggestions");

const listSelect = document.getElementById("list");
const dueSelect = document.getElementById("due");

const customDateRow =
  document.getElementById("customDateRow");

const customDateInput =
  document.getElementById("customDate");

const timeSeparator =
  document.getElementById("timeSeparator");

const timeWrap =
  document.getElementById("timeWrap");

const timeInput =
  document.getElementById("time");

const repeatSeparator =
  document.getElementById("repeatSeparator");

const repeatWrap =
  document.getElementById("repeatWrap");

const repeatValue =
  document.getElementById("repeatValue");

const prioritySelect =
  document.getElementById("priority");

const notesInput =
  document.getElementById("notes");

const addButton =
  document.getElementById("add");

const statusElement =
  document.getElementById("status");

const reminderCard =
  document.querySelector(".reminder-card");

const helperRequired =
  document.getElementById("helperRequired");

const downloadHelperButton =
  document.getElementById("downloadHelper");

const checkHelperButton =
  document.getElementById("checkHelper");

const HELPER_DOWNLOAD_URL =
  "https:" +
  "//github.com/TheCuriousProcrastinator/" +
  "Add-to-Reminders/releases/download/v0.1.1/" +
  "AddToRemindersHelper-0.1.1.pkg";

let currentUrl = "";

let pageIsValid = false;
let listsLoaded = false;

let smartDateActive = false;
let dueBeforeSmartDate = null;
let customDateBeforeSmartDate = "";
let timeBeforeSmartDate = "";
let smartResolvedDate = null;

let availableLists = [];

let smartProjectActive = false;
let listBeforeSmartProject = null;

let visibleProjectSuggestions = [];
let projectSuggestionIndex = -1;

function setStatus(message, type = "") {
  statusElement.textContent = message;
  statusElement.className = type;
}

function escapeHTML(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function insertInboxSeparator() {
  const oldSeparator =
    listSelect.querySelector(
      'option[data-inbox-separator="true"]'
    );

  if (oldSeparator) {
    oldSeparator.remove();
  }

  const inboxOption =
    Array.from(listSelect.options)
      .find(
        option =>
          option.textContent
            .trim()
            .toLowerCase() === "inbox"
      );

  if (!inboxOption) {
    return;
  }

  const separator =
    document.createElement("option");

  separator.disabled = true;
  separator.value = "";
  separator.textContent =
    "────────────";

  separator.dataset.inboxSeparator =
    "true";

  inboxOption.insertAdjacentElement(
    "afterend",
    separator
  );
}

function sortReminderLists(lists) {
  return [...lists].sort(
    (a, b) => {
      const aInbox =
        a.title.toLowerCase() === "inbox";

      const bInbox =
        b.title.toLowerCase() === "inbox";

      if (aInbox && !bInbox) {
        return -1;
      }

      if (!aInbox && bInbox) {
        return 1;
      }

      return a.title.localeCompare(
        b.title,
        undefined,
        { sensitivity: "base" }
      );
    }
  );
}

function currentReminderLists() {
  if (availableLists.length) {
    return availableLists;
  }

  return Array.from(listSelect.options)
    .filter(option =>
      option.value &&
      !option.disabled
    )
    .map(option => ({
      id: option.value,
      title: option.textContent.trim()
    }));
}


function syncRejectedSmartDateRanges(text) {
  const previous =
    lastSmartDateText;

  if (previous === text) {
    return;
  }

  if (
    !previous ||
    !rejectedSmartDateRanges.length
  ) {
    lastSmartDateText = text;
    return;
  }

  let prefix = 0;

  while (
    prefix < previous.length &&
    prefix < text.length &&
    previous[prefix] === text[prefix]
  ) {
    prefix++;
  }

  let suffix = 0;

  while (
    suffix <
      previous.length - prefix &&
    suffix <
      text.length - prefix &&
    previous[
      previous.length - 1 - suffix
    ] ===
      text[
        text.length - 1 - suffix
      ]
  ) {
    suffix++;
  }

  const previousChangedEnd =
    previous.length - suffix;

  const delta =
    text.length -
    previous.length;

  rejectedSmartDateRanges =
    rejectedSmartDateRanges
      .flatMap(range => {
        if (range.end <= prefix) {
          return [range];
        }

        if (
          range.start >=
          previousChangedEnd
        ) {
          return [{
            start:
              range.start + delta,
            end:
              range.end + delta
          }];
        }

        return [];
      });

  lastSmartDateText = text;
}

function parseCurrentSmartDate(text) {
  syncRejectedSmartDateRanges(text);

  return parseSmartDate(
    text,
    new Date(),
    rejectedSmartDateRanges
  );
}

function rejectSmartDateToken(token) {
  if (!token) {
    return;
  }

  const alreadyRejected =
    rejectedSmartDateRanges.some(
      range =>
        range.start === token.start &&
        range.end === token.end
    );

  if (!alreadyRejected) {
    rejectedSmartDateRanges.push({
      start: token.start,
      end: token.end
    });
  }
}

function renderTitleHighlight() {
  const text = titleInput.value;

  const dateParsed =
    parseCurrentSmartDate(text);

  const projectParsed =
    parseSmartProject(
      text,
      currentReminderLists()
    );

  const priorityParsed =
    parseSmartPriority(text);

  const tokens = [];

  activeSmartDateTokens =
    Array.isArray(dateParsed.tokens)
      ? dateParsed.tokens
      : [];

  for (
    const token of
    activeSmartDateTokens
  ) {
    tokens.push({
      start: token.start,
      end: token.end,
      className: "smart-token"
    });
  }

  if (
    projectParsed?.matchedStart != null &&
    projectParsed?.matchedEnd != null
  ) {
    tokens.push({
      start: projectParsed.matchedStart,
      end: projectParsed.matchedEnd,
      className: "smart-token"
    });
  }

  if (
    priorityParsed?.matchedStart != null &&
    priorityParsed?.matchedEnd != null
  ) {
    tokens.push({
      start: priorityParsed.matchedStart,
      end: priorityParsed.matchedEnd,
      className: "smart-token"
    });
  }

  tokens.sort(
    (a, b) => a.start - b.start
  );

  let position = 0;
  let html = "";

  for (const token of tokens) {
    if (token.start < position) {
      continue;
    }

    html += escapeHTML(
      text.slice(position, token.start)
    );

    html +=
      `<span class="${token.className}">` +
      escapeHTML(
        text.slice(token.start, token.end)
      ) +
      "</span>";

    position = token.end;
  }

  html += escapeHTML(
    text.slice(position)
  );

  titleMirror.innerHTML = html;
  titleMirror.scrollLeft =
    titleInput.scrollLeft;
}

function hideProjectSuggestions() {
  projectSuggestions.hidden = true;
  projectSuggestions.innerHTML = "";
  visibleProjectSuggestions = [];
  projectSuggestionIndex = -1;
}

function addListLocally(list) {
  if (
    !availableLists.some(
      item => item.id === list.id
    )
  ) {
    availableLists.push(list);

    availableLists =
      sortReminderLists(
        availableLists
      );
  }

  const exists =
    Array.from(listSelect.options)
      .some(
        option =>
          option.value === list.id
      );

  if (!exists) {
    const option =
      document.createElement("option");

    option.value = list.id;
    option.textContent = list.title;

    listSelect.appendChild(option);

    const options =
      Array.from(listSelect.options)
        .sort(
          (a, b) =>
            a.textContent.localeCompare(
              b.textContent,
              undefined,
              { sensitivity: "base" }
            )
        );

    for (const item of options) {
      listSelect.appendChild(item);
    }

    insertInboxSeparator();
  }
}

async function createReminderList(name) {
  const response =
    await sendNativeMessage({
      action: "createList",
      name
    });

  if (!response.ok) {
    throw new Error(
      response.error ||
      "Could not create list."
    );
  }

  const list = {
    id: response.id,
    title: response.title
  };

  addListLocally(list);

  return list;
}

function renderProjectSuggestions() {
  const caret =
    titleInput.selectionStart ??
    titleInput.value.length;

  const fragment =
    findProjectFragment(
      titleInput.value,
      caret
    );

  if (!fragment) {
    hideProjectSuggestions();
    return;
  }

  const matches =
    filterProjectSuggestions(
      fragment,
      currentReminderLists()
    );

  const items =
    matches.map(list => ({
      type: "list",
      list
    }));

  const requestedName =
    fragment.query.trim();

  const exactExisting =
    requestedName
      ? currentReminderLists().some(
          list =>
            list.title
              .trim()
              .toLocaleLowerCase() ===
            requestedName
              .toLocaleLowerCase()
        )
      : false;

  // Existing matches stay first.
  // Creating the exact typed name is always
  // available unless that exact list already exists.
  if (
    requestedName &&
    !exactExisting
  ) {
    items.push({
      type: "create",
      name: requestedName
    });
  }

  if (!items.length) {
    hideProjectSuggestions();
    return;
  }

  visibleProjectSuggestions = items;

  if (
    projectSuggestionIndex < 0 ||
    projectSuggestionIndex >= items.length
  ) {
    projectSuggestionIndex = 0;
  }

  projectSuggestions.innerHTML = "";

  items.forEach((item, index) => {
    const button =
      document.createElement("button");

    button.type = "button";
    button.className =
      "project-suggestion";

    if (
      index === projectSuggestionIndex
    ) {
      button.classList.add("active");
    }

    const symbol =
      document.createElement("span");

    symbol.className =
      "project-suggestion-slash";

    const name =
      document.createElement("span");

    if (item.type === "create") {
      symbol.textContent = "+";
      name.textContent =
        `Create "${item.name}"`;
    } else {
      symbol.textContent = "/";
      name.textContent =
        item.list.title;
    }

    button.append(
      symbol,
      name
    );

    button.addEventListener(
      "mousedown",
      event => {
        event.preventDefault();
      }
    );

    button.addEventListener(
      "click",
      async () => {
        await chooseProjectSuggestion(
          item
        );
      }
    );

    projectSuggestions.appendChild(
      button
    );
  });

  projectSuggestions.hidden = false;
}

async function chooseProjectSuggestion(item) {
  let list;

  if (item.type === "create") {
    try {
      setStatus(
        `Creating ${item.name}…`
      );

      list =
        await createReminderList(
          item.name
        );

      setStatus("");

    } catch (error) {
      setStatus(
        `Could not create list: ${error.message}`,
        "error"
      );
      return;
    }

  } else {
    list = item.list;
  }

  const caret =
    titleInput.selectionStart ??
    titleInput.value.length;

  const fragment =
    findProjectFragment(
      titleInput.value,
      caret
    );

  if (!fragment) {
    return;
  }

  const before =
    titleInput.value.slice(
      0,
      fragment.start
    );

  const after =
    titleInput.value.slice(
      fragment.end
    );

  const token =
    `/${list.title}`;

  const needsSpace =
    after.length > 0 &&
    !after.startsWith(" ");

  titleInput.value =
    before +
    token +
    (needsSpace ? " " : "") +
    after;

  const newCaret =
    before.length +
    token.length +
    (needsSpace ? 1 : 0);

  titleInput.focus();

  titleInput.setSelectionRange(
    newCaret,
    newCaret
  );

  hideProjectSuggestions();

  applySmartProject();
  applySmartDate();
  applySmartPriority();

  renderTitleHighlight();
  updateAddButton();
}

function applySmartProject() {
  const parsed =
    parseSmartProject(
      titleInput.value,
      currentReminderLists()
    );

  if (!parsed) {
    if (smartProjectActive) {
      const stillExists =
        currentReminderLists().some(
          list =>
            list.id ===
            listBeforeSmartProject
        );

      if (
        stillExists &&
        listBeforeSmartProject
      ) {
        listSelect.value =
          listBeforeSmartProject;
      }

      smartProjectActive = false;
      listBeforeSmartProject = null;
    }

    return;
  }

  if (!smartProjectActive) {
    listBeforeSmartProject =
      listSelect.value;

    smartProjectActive = true;
  }

  listSelect.value =
    parsed.listId;
}

function applySmartPriority() {
  const parsed =
    parseSmartPriority(
      titleInput.value
    );

  if (!parsed) {
    return;
  }

  prioritySelect.value =
    String(parsed.value);
}

function cleanTitleForSave(text) {
  const dateParsed =
    parseCurrentSmartDate(text);

  const projectParsed =
    parseSmartProject(
      text,
      currentReminderLists()
    );

  const priorityParsed =
    parseSmartPriority(text);

  const ranges = [];

  for (
    const token of
    dateParsed.tokens || []
  ) {
    ranges.push([
      token.start,
      token.end
    ]);
  }

  if (
    projectParsed?.matchedStart != null &&
    projectParsed?.matchedEnd != null
  ) {
    ranges.push([
      projectParsed.matchedStart,
      projectParsed.matchedEnd
    ]);
  }

  if (
    priorityParsed?.matchedStart != null &&
    priorityParsed?.matchedEnd != null
  ) {
    ranges.push([
      priorityParsed.matchedStart,
      priorityParsed.matchedEnd
    ]);
  }

  ranges.sort(
    (a, b) => b[0] - a[0]
  );

  let result = text;

  for (const [start, end] of ranges) {
    result =
      result.slice(0, start) +
      result.slice(end);
  }

  return result
    .replace(/\s+/g, " ")
    .trim();
}

function updateAddButton() {
  addButton.disabled =
    !pageIsValid ||
    !listsLoaded ||
    !titleInput.value.trim() ||
    !listSelect.value;
}

function refreshDateTimeControls() {
  const custom =
    dueSelect.value === "custom";

  const hasDate =
    dueSelect.value !== "none";

  customDateRow.hidden = !custom;

  timeWrap.hidden = !hasDate;
  timeSeparator.hidden = !hasDate;

  if (!hasDate) {
    timeInput.value = "";
  }
}

function formatRepeatLabel(label) {
  if (!label) {
    return "";
  }

  return label.charAt(0).toUpperCase() +
    label.slice(1);
}

function refreshRepeatRow(parsed) {
  const recurrence =
    parsed?.recurrence;

  if (!recurrence) {
    repeatSeparator.hidden = true;
    repeatWrap.hidden = true;
    repeatValue.textContent = "";
    return;
  }

  repeatValue.textContent =
    formatRepeatLabel(
      recurrence.label ||
      "Repeating"
    );

  repeatSeparator.hidden = false;
  repeatWrap.hidden = false;
}

function sendNativeMessage(message) {
  return new Promise(
    (resolve, reject) => {
      chrome.runtime.sendNativeMessage(
        HOST_NAME,
        message,
        response => {
          if (chrome.runtime.lastError) {
            reject(
              new Error(
                chrome.runtime.lastError.message
              )
            );
            return;
          }

          if (!response) {
            reject(
              new Error(
                "No response from Mac helper."
              )
            );
            return;
          }

          resolve(response);
        }
      );
    }
  );
}

async function consumePendingCapture() {
  try {
    const stored =
      await chrome.storage.local.get(
        "pendingReminderCapture"
      );

    const pending =
      stored.pendingReminderCapture;

    if (!pending) {
      return null;
    }

    await chrome.storage.local.remove(
      "pendingReminderCapture"
    );

    // Ignore stale captures.
    if (
      !pending.createdAt ||
      Date.now() - pending.createdAt >
        2 * 60 * 1000
    ) {
      return null;
    }

    return pending;

  } catch {
    return null;
  }
}

async function loadCurrentPage() {
  const [tab] = await chrome.tabs.query({
    active: true,
    currentWindow: true
  });

  const pending =
    await consumePendingCapture();

  if (!tab && !pending) {
    setStatus(
      "Could not read the current tab.",
      "error"
    );
    return;
  }

  currentUrl =
    pending?.url ||
    tab?.url ||
    "";

  pageIsValid =
    currentUrl.startsWith("http://") ||
    currentUrl.startsWith("https://");

  titleInput.value =
    pending?.title ||
    tab?.title ||
    "";

  try {
    const url =
      new URL(currentUrl);

    urlElement.textContent =
      url.hostname.replace(
        /^www\./,
        ""
      );

    urlElement.title =
      currentUrl;

  } catch {
    urlElement.textContent =
      currentUrl;
  }

  renderTitleHighlight();

  if (!pageIsValid) {
    setStatus(
      "This works on normal web pages only.",
      "error"
    );
  }

  titleInput.focus();
  titleInput.select();

  updateAddButton();
}

function isMissingHelperError(error) {
  const message =
    String(
      error?.message ||
      error ||
      ""
    ).toLowerCase();

  return (
    message.includes(
      "native messaging host not found"
    ) ||
    message.includes(
      "specified native messaging host not found"
    ) ||
    message.includes(
      "access to the specified native messaging host is forbidden"
    )
  );
}

function showHelperRequired() {
  listsLoaded = false;

  reminderCard.hidden = true;
  addButton.hidden = true;
  statusElement.hidden = true;
  helperRequired.hidden = false;

  updateAddButton();
}

function hideHelperRequired() {
  helperRequired.hidden = true;
  reminderCard.hidden = false;
  addButton.hidden = false;
  statusElement.hidden = false;
}

async function loadLists() {
  listsLoaded = false;
  updateAddButton();

  try {
    const response =
      await sendNativeMessage({
        action: "lists"
      });

    if (!response.ok) {
      throw new Error(
        response.error ||
        "Could not load Reminders lists."
      );
    }

    availableLists =
      sortReminderLists(
        response.lists || []
      );

    if (!availableLists.length) {
      throw new Error(
        "No Reminders lists found."
      );
    }

    listSelect.innerHTML = "";

    for (const list of availableLists) {
      const option =
        document.createElement(
          "option"
        );

      option.value = list.id;
      option.textContent =
        list.title;

      listSelect.appendChild(option);
    }

    const stored =
      await chrome.storage.local.get(
        "lastListId"
      );

    const remembered =
      availableLists.some(
        list =>
          list.id ===
          stored.lastListId
      );

    if (remembered) {
      listSelect.value =
        stored.lastListId;

    } else {
      const remindersList =
        availableLists.find(
          list =>
            list.title ===
            "Reminders"
        );

      if (remindersList) {
        listSelect.value =
          remindersList.id;
      }
    }

    insertInboxSeparator();

    listSelect.disabled = false;
    listsLoaded = true;

    hideHelperRequired();

    applySmartProject();
    renderTitleHighlight();

    if (pageIsValid) {
      setStatus("");
    }

    updateAddButton();

  } catch (error) {
    listSelect.innerHTML =
      "<option>Mac helper unavailable</option>";

    listsLoaded = false;

    if (isMissingHelperError(error)) {
      showHelperRequired();
      return;
    }

    hideHelperRequired();

    setStatus(
      `Could not connect to Reminders: ${error.message}`,
      "error"
    );

    updateAddButton();
  }
}

function toISO(date) {
  const year =
    date.getFullYear();

  const month =
    String(
      date.getMonth() + 1
    ).padStart(2, "0");

  const day =
    String(
      date.getDate()
    ).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

function formatSmartDateLabel(iso) {
  const [year, month, day] =
    iso.split("-").map(Number);

  const date =
    new Date(
      year,
      month - 1,
      day
    );

  const options = {
    weekday: "short",
    month: "short",
    day: "numeric"
  };

  if (
    year !==
    new Date().getFullYear()
  ) {
    options.year = "numeric";
  }

  return new Intl.DateTimeFormat(
    "en-US",
    options
  ).format(date);
}

function setSmartDateOption(iso) {
  let option =
    dueSelect.querySelector(
      'option[value="smart"]'
    );

  if (!option) {
    option =
      document.createElement(
        "option"
      );

    option.value = "smart";
    option.disabled = true;

    const custom =
      dueSelect.querySelector(
        'option[value="custom"]'
      );

    dueSelect.insertBefore(
      option,
      custom
    );
  }

  option.textContent =
    formatSmartDateLabel(iso);

  smartResolvedDate = iso;
  dueSelect.value = "smart";
}

function clearSmartDateOption() {
  const option =
    dueSelect.querySelector(
      'option[value="smart"]'
    );

  if (option) {
    option.remove();
  }

  smartResolvedDate = null;
}

function applySmartDate() {
  const parsed =
    parseCurrentSmartDate(
      titleInput.value
    );

  renderTitleHighlight();
  refreshRepeatRow(parsed);

  if (
    !parsed.matchedText ||
    !parsed.due
  ) {
    if (smartDateActive) {
      clearSmartDateOption();

      dueSelect.value =
        dueBeforeSmartDate ||
        "none";

      customDateInput.value =
        customDateBeforeSmartDate ||
        "";

      timeInput.value =
        timeBeforeSmartDate ||
        "";

      smartDateActive = false;
      dueBeforeSmartDate = null;
      customDateBeforeSmartDate = "";
      timeBeforeSmartDate = "";

      refreshDateTimeControls();
    }

    return;
  }

  if (!smartDateActive) {
    dueBeforeSmartDate =
      dueSelect.value;

    customDateBeforeSmartDate =
      customDateInput.value;

    timeBeforeSmartDate =
      timeInput.value;

    smartDateActive = true;
  }

  const today =
    new Date();

  today.setHours(
    0, 0, 0, 0
  );

  const tomorrow =
    new Date(today);

  tomorrow.setDate(
    tomorrow.getDate() + 1
  );

  if (
    parsed.due ===
    toISO(today)
  ) {
    clearSmartDateOption();

    dueSelect.value =
      "today";

    customDateInput.value =
      "";

  } else if (
    parsed.due ===
    toISO(tomorrow)
  ) {
    clearSmartDateOption();

    dueSelect.value =
      "tomorrow";

    customDateInput.value =
      "";

  } else {
    setSmartDateOption(
      parsed.due
    );

    customDateInput.value =
      parsed.due;
  }

  timeInput.value =
    parsed.time || "";

  refreshDateTimeControls();
}

dueSelect.addEventListener(
  "change",
  () => {
    smartDateActive = false;

    if (
      dueSelect.value !==
      "smart"
    ) {
      clearSmartDateOption();
    }

    refreshDateTimeControls();

    if (
      dueSelect.value ===
      "custom"
    ) {
      customDateInput.focus();
    }
  }
);

titleInput.addEventListener(
  "input",
  () => {
    applySmartProject();
    applySmartDate();
    applySmartPriority();

    renderProjectSuggestions();
    renderTitleHighlight();

    updateAddButton();
  }
);

titleInput.addEventListener(
  "click",
  () => {
    if (
      titleInput.selectionStart !==
      titleInput.selectionEnd
    ) {
      return;
    }

    const caret =
      titleInput.selectionStart;

    if (caret == null) {
      return;
    }

    const token =
      activeSmartDateTokens.find(
        item =>
          (
            caret > item.start &&
            caret < item.end
          ) ||
          (
            caret === item.start &&
            item.end > item.start
          ) ||
          (
            caret === item.end &&
            item.end > item.start
          )
      );

    if (!token) {
      return;
    }

    rejectSmartDateToken(token);

    applySmartDate();
    renderTitleHighlight();
    updateAddButton();
  }
);

titleInput.addEventListener(
  "keydown",
  event => {
    if (
      projectSuggestions.hidden ||
      !visibleProjectSuggestions.length
    ) {
      return;
    }

    if (
      event.key ===
      "ArrowDown"
    ) {
      event.preventDefault();

      projectSuggestionIndex =
        (
          projectSuggestionIndex + 1
        ) %
        visibleProjectSuggestions.length;

      renderProjectSuggestions();
      return;
    }

    if (
      event.key ===
      "ArrowUp"
    ) {
      event.preventDefault();

      projectSuggestionIndex =
        projectSuggestionIndex <= 0
          ? visibleProjectSuggestions.length - 1
          : projectSuggestionIndex - 1;

      renderProjectSuggestions();
      return;
    }

    if (
      event.key === "Enter" &&
      projectSuggestionIndex >= 0
    ) {
      const selectedItem =
        visibleProjectSuggestions[
          projectSuggestionIndex
        ];

      // Creating a brand-new Reminders list
      // always requires an explicit click.
      if (
        selectedItem?.type === "create"
      ) {
        event.preventDefault();
        return;
      }

      event.preventDefault();

      chooseProjectSuggestion(
        selectedItem
      );

      return;
    }

    if (event.key === "Escape") {
      event.preventDefault();
      hideProjectSuggestions();
    }
  }
);

titleInput.addEventListener(
  "scroll",
  () => {
    titleMirror.scrollLeft =
      titleInput.scrollLeft;
  }
);

titleInput.addEventListener(
  "blur",
  () => {
    titleInput.scrollLeft = 0;
    titleMirror.scrollLeft = 0;

    setTimeout(
      hideProjectSuggestions,
      100
    );
  }
);

titleInput.addEventListener(
  "focus",
  () => {
    requestAnimationFrame(() => {
      titleMirror.scrollLeft =
        titleInput.scrollLeft;
    });
  }
);

listSelect.addEventListener(
  "change",
  async () => {
    const parsed =
      parseSmartProject(
        titleInput.value,
        currentReminderLists()
      );

    if (
      parsed &&
      smartProjectActive
    ) {
      const selected =
        currentReminderLists().find(
          list =>
            list.id ===
            listSelect.value
        );

      if (selected) {
        titleInput.value =
          titleInput.value.slice(
            0,
            parsed.matchedStart
          ) +
          `/${selected.title}` +
          titleInput.value.slice(
            parsed.matchedEnd
          );

        renderTitleHighlight();
      }
    }

    await chrome.storage.local.set({
      lastListId:
        listSelect.value
    });
  }
);

form.addEventListener(
  "submit",
  async event => {
    event.preventDefault();

    const parsed =
      parseCurrentSmartDate(
        titleInput.value
      );

    const title =
      cleanTitleForSave(
        titleInput.value
      );

    if (
      !title ||
      !listSelect.value ||
      !pageIsValid
    ) {
      return;
    }

    let due =
      dueSelect.value;

    if (due === "smart") {
      due =
        smartResolvedDate ||
        parsed.due ||
        "none";
    }

    if (due === "custom") {
      if (!customDateInput.value) {
        setStatus(
          "Choose a date first.",
          "error"
        );

        customDateInput.focus();
        return;
      }

      due =
        customDateInput.value;
    }

    const time =
      due === "none"
        ? ""
        : timeInput.value;

    addButton.disabled = true;
    addButton.textContent =
      "Adding…";

    setStatus("");

    try {
      const response =
        await sendNativeMessage({
          action: "add",
          title,
          url: currentUrl,
          listId: listSelect.value,
          due,
          time,
          recurrence:
            parsed.recurrence,

          priority:
            Number(
              prioritySelect.value
            ),

          notes:
            notesInput.value.trim()
        });

      if (!response.ok) {
        throw new Error(
          response.error ||
          "Could not create reminder."
        );
      }

      await chrome.storage.local.set({
        lastListId:
          listSelect.value
      });

      setStatus(
        `Added to ${response.list}`,
        "success"
      );

      addButton.textContent =
        "Added ✓";

      setTimeout(
        () => window.close(),
        650
      );

    } catch (error) {
      setStatus(
        `Could not add reminder: ${error.message}`,
        "error"
      );

      addButton.textContent =
        "Add Reminder";

      updateAddButton();
    }
  }
);

downloadHelperButton.addEventListener(
  "click",
  () => {
    chrome.tabs.create({
      url: HELPER_DOWNLOAD_URL
    });
  }
);

checkHelperButton.addEventListener(
  "click",
  async () => {
    checkHelperButton.disabled = true;
    checkHelperButton.textContent =
      "Checking…";

    try {
      await loadLists();
    } finally {
      checkHelperButton.disabled = false;
      checkHelperButton.textContent =
        "Check Again";
    }
  }
);

async function init() {
  await loadCurrentPage();
  await loadLists();

  refreshDateTimeControls();

  applySmartProject();
  applySmartDate();

  renderTitleHighlight();

  refreshRepeatRow(
    parseCurrentSmartDate(
      titleInput.value
    )
  );
}

init();
