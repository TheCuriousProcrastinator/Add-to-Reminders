import {
  getDoItThenThemeInfo
} from "./native-bridge.js";

const PALETTES = {
  paperEmber: {
    mode: "light",
    canvas: "#F7F7F5",
    surface: "#FFFFFF",
    surfaceRaised: "#FAFAF8",
    hover: "#ECEAE5",
    border: "#DDDAD4",
    textPrimary: "#1F1F1D",
    textSecondary: "#686661",
    accent: "#D65A26",
    accentStrong: "#C64F1A",
    accentSoft: "#FBE9E1",
    onAccent: "#11110F"
  },

  polarInk: {
    mode: "light",
    canvas: "#F4F7F8",
    surface: "#FFFFFF",
    surfaceRaised: "#F8FAFB",
    hover: "#E5EDF0",
    border: "#D3DEE3",
    textPrimary: "#142027",
    textSecondary: "#596A73",
    accent: "#0E7C8C",
    accentStrong: "#086575",
    accentSoft: "#DDF2F5",
    onAccent: "#FFFFFF"
  },

  mintCandy: {
    mode: "light",
    canvas: "#F5FFFB",
    surface: "#FFFFFF",
    surfaceRaised: "#FFFFFF",
    hover: "#EAFBF5",
    border: "#CFE9DF",
    textPrimary: "#24302C",
    textSecondary: "#56685F",
    accent: "#D43E86",
    accentStrong: "#BF3276",
    accentSoft: "#F8E0EC",
    onAccent: "#000000"
  },

  carbonEmber: {
    mode: "dark",
    canvas: "#171716",
    surface: "#22211F",
    surfaceRaised: "#292825",
    hover: "#302E2B",
    border: "#3C3934",
    textPrimary: "#F2F1EE",
    textSecondary: "#B1AEA6",
    accent: "#FF8A52",
    accentStrong: "#C4511A",
    accentSoft: "#3A241B",
    onAccent: "#171716"
  },

  midnightCircuit: {
    mode: "dark",
    canvas: "#0F141A",
    surface: "#18212B",
    surfaceRaised: "#1D2935",
    hover: "#23323F",
    border: "#30404D",
    textPrimary: "#F0F5F7",
    textSecondary: "#A5B3BB",
    accent: "#4CC9F0",
    accentStrong: "#1FA8D3",
    accentSoft: "#15323D",
    onAccent: "#0F141A"
  },

  plumStatic: {
    mode: "dark",
    canvas: "#171319",
    surface: "#251D28",
    surfaceRaised: "#2D2331",
    hover: "#35293A",
    border: "#49384D",
    textPrimary: "#F6F0F7",
    textSecondary: "#B9AABF",
    accent: "#E58ACB",
    accentStrong: "#C967AB",
    accentSoft: "#3B2337",
    onAccent: "#171319"
  }
};

const THEME_VARIABLES = [
  "--bg",
  "--card",
  "--panel",
  "--text",
  "--secondary",
  "--separator",
  "--control",
  "--control-bg",
  "--border",
  "--control-border",
  "--row-hover",
  "--accent",
  "--accent-hover",
  "--focus",
  "--smart-bg",
  "--on-accent"
];

export function resolveDoItThenTheme(
  info,
  prefersDark
) {
  if (
    !info ||
    info.ok !== true ||
    info.available !== true ||
    info.schemaVersion !== 1
  ) {
    return null;
  }

  let themeID;

  switch (info.appearanceMode) {
  case "light":
    themeID =
      info.lightTheme;
    break;

  case "dark":
    themeID =
      info.darkTheme;
    break;

  case "system":
    themeID =
      prefersDark
        ? info.darkTheme
        : info.lightTheme;
    break;

  default:
    return null;
  }

  const palette =
    PALETTES[themeID];

  if (!palette) {
    return null;
  }

  if (
    info.appearanceMode === "light" &&
    palette.mode !== "light"
  ) {
    return null;
  }

  if (
    info.appearanceMode === "dark" &&
    palette.mode !== "dark"
  ) {
    return null;
  }

  if (
    info.appearanceMode === "system" &&
    palette.mode !== (
      prefersDark
        ? "dark"
        : "light"
    )
  ) {
    return null;
  }

  return {
    id: themeID,
    ...palette
  };
}

export function cssVariablesForTheme(
  theme
) {
  if (!theme) {
    return null;
  }

  return {
    "--bg":
      theme.canvas,

    "--card":
      theme.surface,

    "--panel":
      theme.surface,

    "--text":
      theme.textPrimary,

    "--secondary":
      theme.textSecondary,

    "--separator":
      theme.border,

    "--control":
      theme.surfaceRaised,

    "--control-bg":
      theme.surfaceRaised,

    "--border":
      theme.border,

    "--control-border":
      theme.border,

    "--row-hover":
      theme.hover,

    "--accent":
      theme.accent,

    "--accent-hover":
      theme.accentStrong,

    "--focus":
      theme.accentSoft,

    "--smart-bg":
      theme.accentSoft,

    "--on-accent":
      theme.onAccent
  };
}

function clearAppliedTheme() {
  const root =
    document.documentElement;

  for (
    const variable of
    THEME_VARIABLES
  ) {
    root.style.removeProperty(
      variable
    );
  }

  root.style.removeProperty(
    "color-scheme"
  );

  delete root.dataset.doitthenTheme;
}

export async function applyDoItThenTheme() {
  clearAppliedTheme();

  let info;

  try {
    info =
      await getDoItThenThemeInfo();
  } catch {
    return {
      source: "system",
      theme: null
    };
  }

  const media =
    window.matchMedia(
      "(prefers-color-scheme: dark)"
    );

  const theme =
    resolveDoItThenTheme(
      info,
      media.matches
    );

  if (!theme) {
    return {
      source: "system",
      theme: null
    };
  }

  const root =
    document.documentElement;

  const variables =
    cssVariablesForTheme(
      theme
    );

  for (
    const [name, value] of
    Object.entries(variables)
  ) {
    root.style.setProperty(
      name,
      value
    );
  }

  root.style.setProperty(
    "color-scheme",
    theme.mode
  );

  root.dataset.doitthenTheme =
    theme.id;

  return {
    source: "doitthen",
    theme
  };
}
