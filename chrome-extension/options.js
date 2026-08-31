const HOST_NAME =
  "com.alex.addtoreminders";

const DEFAULTS = {
  captureDefaultList: "last",
  captureDefaultListTitle: "",
  captureDefaultDate: "none",
  captureDefaultPriority: "0",
  smartDateRecognition: true
};

const listSelect =
  document.getElementById(
    "defaultList"
  );

const dateSelect =
  document.getElementById(
    "defaultDate"
  );

const prioritySelect =
  document.getElementById(
    "defaultPriority"
  );

const smartToggle =
  document.getElementById(
    "smartDateRecognition"
  );

const statusElement =
  document.getElementById(
    "status"
  );

let savedSettings = {
  ...DEFAULTS
};

let statusTimer = null;

function setStatus(
  message,
  type = ""
) {
  clearTimeout(statusTimer);

  statusElement.textContent =
    message;

  statusElement.className =
    type;

  if (type === "saved") {
    statusTimer = setTimeout(
      () => {
        statusElement.textContent =
          "Changes save automatically.";

        statusElement.className = "";
      },
      1200
    );
  }
}

function sendNativeMessage(message) {
  return new Promise(
    (resolve, reject) => {
      chrome.runtime.sendNativeMessage(
        HOST_NAME,
        message,
        response => {
          if (
            chrome.runtime.lastError
          ) {
            reject(
              new Error(
                chrome.runtime
                  .lastError
                  .message
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

function normalizeLists(response) {
  const candidates = [
    response?.lists,
    response?.calendars,
    response?.items
  ];

  let lists =
    candidates.find(
      Array.isArray
    ) || [];

  lists = lists.filter(
    item =>
      item &&
      item.id &&
      item.title
  );

  const INBOX_FIRST_SETTINGS_V013 = true;

  return [...lists].sort(
    (a, b) => {
      const aInbox =
        a.title.trim().toLowerCase() ===
        "inbox";

      const bInbox =
        b.title.trim().toLowerCase() ===
        "inbox";

      if (aInbox && !bInbox) {
        return -1;
      }

      if (!aInbox && bInbox) {
        return 1;
      }

      return a.title.localeCompare(
        b.title,
        undefined,
        {
          sensitivity: "base",
          numeric: true
        }
      );
    }
  );
}

async function loadReminderLists() {
  const selected =
    savedSettings.captureDefaultList;

  listSelect.innerHTML = "";

  const lastOption =
    document.createElement(
      "option"
    );

  lastOption.value = "last";
  lastOption.textContent =
    "Last used";

  listSelect.appendChild(
    lastOption
  );

  try {
    const platform =
      await chrome.runtime
        .getPlatformInfo();

    if (platform.os !== "mac") {
      throw new Error(
        "Reminders lists are available on macOS only."
      );
    }

    const response =
      await sendNativeMessage({
        action: "lists"
      });

    if (!response?.ok) {
      throw new Error(
        response?.error ||
        "Could not load Reminders lists."
      );
    }

    const lists =
      normalizeLists(response);

    for (const list of lists) {
      const option =
        document.createElement(
          "option"
        );

      option.value = list.id;
      option.textContent =
        list.title;

      listSelect.appendChild(
        option
      );
    }

    const exists =
      selected === "last" ||
      lists.some(
        list =>
          list.id === selected
      );

    listSelect.value =
      exists
        ? selected
        : "last";

    if (
      !exists &&
      selected !== "last"
    ) {
      await chrome.storage.local.set({
        captureDefaultList:
          "last",
        captureDefaultListTitle:
          ""
      });

      savedSettings.captureDefaultList =
        "last";

      savedSettings.captureDefaultListTitle =
        "";
    }

  } catch (error) {
    if (
      selected &&
      selected !== "last"
    ) {
      const option =
        document.createElement(
          "option"
        );

      option.value = selected;

      option.textContent =
        savedSettings
          .captureDefaultListTitle ||
        "Selected list";

      listSelect.appendChild(
        option
      );

      listSelect.value =
        selected;
    }

    setStatus(
      "Could not refresh Reminders lists. Existing settings are preserved.",
      "error"
    );
  }
}

async function save(
  values
) {
  savedSettings = {
    ...savedSettings,
    ...values
  };

  await chrome.storage.local.set(
    values
  );

  setStatus(
    "Saved",
    "saved"
  );
}

listSelect.addEventListener(
  "change",
  async () => {
    const option =
      listSelect.selectedOptions[0];

    await save({
      captureDefaultList:
        listSelect.value,

      captureDefaultListTitle:
        listSelect.value === "last"
          ? ""
          : (
              option?.textContent ||
              ""
            )
    });
  }
);

dateSelect.addEventListener(
  "change",
  async () => {
    await save({
      captureDefaultDate:
        dateSelect.value
    });
  }
);

prioritySelect.addEventListener(
  "change",
  async () => {
    await save({
      captureDefaultPriority:
        prioritySelect.value
    });
  }
);

smartToggle.addEventListener(
  "change",
  async () => {
    await save({
      smartDateRecognition:
        smartToggle.checked
    });
  }
);

async function init() {
  const stored =
    await chrome.storage.local.get(
      DEFAULTS
    );

  savedSettings = {
    ...DEFAULTS,
    ...stored
  };

  if (
    !["none", "today", "tomorrow"]
      .includes(
        savedSettings
          .captureDefaultDate
      )
  ) {
    savedSettings.captureDefaultDate =
      "none";
  }

  if (
    !["0", "1", "5", "9"]
      .includes(
        String(
          savedSettings
            .captureDefaultPriority
        )
      )
  ) {
    savedSettings.captureDefaultPriority =
      "0";
  }

  savedSettings.captureDefaultPriority =
    String(
      savedSettings
        .captureDefaultPriority
    );

  savedSettings.smartDateRecognition =
    savedSettings
      .smartDateRecognition !== false;

  dateSelect.value =
    savedSettings.captureDefaultDate;

  prioritySelect.value =
    savedSettings
      .captureDefaultPriority;

  smartToggle.checked =
    savedSettings
      .smartDateRecognition;

  await loadReminderLists();
}

init();
