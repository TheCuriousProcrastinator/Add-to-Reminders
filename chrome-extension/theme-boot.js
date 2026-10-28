(() => {
  const root = document.documentElement;

  const keys = [
    "--bg", "--card", "--panel", "--text",
    "--secondary", "--separator", "--control",
    "--control-bg", "--border", "--control-border",
    "--row-hover", "--accent", "--accent-hover",
    "--focus", "--smart-bg", "--on-accent"
  ];

  window.doitThenThemeBootReady = (async () => {
    try {
      const stored = await chrome.storage.local.get(
        "doitThenCachedTheme"
      );

      const cache = stored.doitThenCachedTheme;
      const mode = matchMedia(
        "(prefers-color-scheme: dark)"
      ).matches ? "dark" : "light";

      const theme = cache?.version === 1
        ? cache[mode]
        : null;

      const colors = theme?.colors;

      if (
        theme?.mode === mode &&
        colors &&
        keys.every(key =>
          typeof colors[key] === "string" &&
          /^#[0-9a-fA-F]{6}$/.test(colors[key])
        )
      ) {
        for (const key of keys) {
          root.style.setProperty(key, colors[key]);
        }

        root.style.setProperty("color-scheme", mode);

        if (typeof theme.id === "string") {
          root.dataset.doitthenTheme = theme.id;
        }
      }
    } catch {
      // The existing standalone colors remain available.
    } finally {
      root.dataset.themeReady = "true";
    }
  })();
})();
