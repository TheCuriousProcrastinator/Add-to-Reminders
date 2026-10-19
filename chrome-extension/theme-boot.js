(() => {
  const root = document.documentElement;
  const keys = [
    "--bg", "--card", "--panel", "--text",
    "--secondary", "--separator", "--control",
    "--control-bg", "--border", "--control-border",
    "--row-hover", "--accent", "--accent-hover",
    "--focus", "--smart-bg", "--on-accent"
  ];

  const ready = chrome.storage.local.get(
    "doitThenCachedTheme"
  ).then(stored => {
    const cache = stored.doitThenCachedTheme;
    if (cache?.version !== 1) return;

    const dark = matchMedia(
      "(prefers-color-scheme: dark)"
    ).matches;

    const theme = dark ? cache.dark : cache.light;
    if (!theme || !["light", "dark"].includes(theme.mode)) {
      return;
    }

    if (
      typeof theme.id !== "string" ||
      !/^[a-zA-Z][a-zA-Z0-9]*$/.test(theme.id) ||
      !theme.colors ||
      !keys.every(key =>
        typeof theme.colors[key] === "string" &&
        /^#[0-9a-fA-F]{6}$/.test(theme.colors[key])
      )
    ) return;

    for (const key of keys) {
      root.style.setProperty(key, theme.colors[key]);
    }

    root.style.setProperty("color-scheme", theme.mode);
    root.dataset.doitthenTheme = theme.id;
  }).catch(() => {
    // Standalone CSS remains available.
  }).finally(() => {
    root.dataset.themeReady = "true";
  });

  window.doitThenThemeBootReady = ready;
})();
