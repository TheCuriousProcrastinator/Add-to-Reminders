import assert from "node:assert/strict";

import {
  resolveDoItThenTheme,
  resolveStandaloneTheme,
  cssVariablesForTheme,
  cacheRecordForThemeInfo
} from "./extension-theme.js";

const base = {
  ok: true,
  available: true,
  schemaVersion: 1,
  appearanceMode: "system",
  lightTheme: "paperEmber",
  darkTheme: "midnightCircuit"
};

{
  const theme =
    resolveDoItThenTheme(
      base,
      false
    );

  assert.equal(
    theme.id,
    "paperEmber"
  );

  assert.equal(
    theme.mode,
    "light"
  );

  assert.equal(
    theme.accent,
    "#D65A26"
  );
}

{
  const theme =
    resolveDoItThenTheme(
      base,
      true
    );

  assert.equal(
    theme.id,
    "midnightCircuit"
  );

  assert.equal(
    theme.mode,
    "dark"
  );

  assert.equal(
    theme.accent,
    "#4CC9F0"
  );
}

{
  const theme =
    resolveDoItThenTheme(
      {
        ...base,
        appearanceMode:
          "light",
        lightTheme:
          "polarInk"
      },
      true
    );

  assert.equal(
    theme.id,
    "polarInk"
  );

  assert.equal(
    theme.mode,
    "light"
  );
}

{
  const theme =
    resolveDoItThenTheme(
      {
        ...base,
        appearanceMode:
          "dark",
        darkTheme:
          "plumStatic"
      },
      false
    );

  assert.equal(
    theme.id,
    "plumStatic"
  );

  assert.equal(
    theme.mode,
    "dark"
  );
}

assert.equal(
  resolveDoItThenTheme(
    {
      ...base,
      available: false
    },
    false
  ),
  null
);

assert.equal(
  resolveDoItThenTheme(
    {
      ...base,
      schemaVersion: 2
    },
    false
  ),
  null
);

assert.equal(
  resolveDoItThenTheme(
    {
      ...base,
      lightTheme:
        "unknownTheme"
    },
    false
  ),
  null
);

{
  const theme =
    resolveDoItThenTheme(
      {
        ...base,
        appearanceMode:
          "light",
        lightTheme:
          "mintCandy"
      },
      false
    );

  const variables =
    cssVariablesForTheme(
      theme
    );

  assert.equal(
    variables["--bg"],
    "#F5FFFB"
  );

  assert.equal(
    variables["--accent"],
    "#D43E86"
  );

  assert.equal(
    variables["--on-accent"],
    "#000000"
  );
}

console.log(
  "Extension theme mapping tests passed"
);


// Dynamic colors must override existing built-in shades.
const dynamic = {
  ...base,
  appearanceMode: "light",
  palettes: {
    light: {
      canvas: "#010203",
      surface: "#FFFFFF",
      surfaceRaised: "#EEEEEE",
      hover: "#CCCCCC",
      border: "#AAAAAA",
      textPrimary: "#111111",
      textSecondary: "#222222",
      accent: "#A1B2C3",
      accentStrong: "#B2C3D4",
      accentSoft: "#DDEEFF",
      onAccent: "#000000"
    },
    dark: {
      canvas: "#101112",
      surface: "#202122",
      surfaceRaised: "#303132",
      hover: "#404142",
      border: "#505152",
      textPrimary: "#F1F2F3",
      textSecondary: "#A1A2A3",
      accent: "#334455",
      accentStrong: "#445566",
      accentSoft: "#556677",
      onAccent: "#FFFFFF"
    }
  }
};

assert.equal(
  resolveDoItThenTheme(dynamic, false).accent,
  "#A1B2C3"
);

assert.equal(
  cssVariablesForTheme(
    resolveDoItThenTheme(dynamic, false)
  )["--bg"],
  "#010203"
);

assert.equal(
  resolveDoItThenTheme(
    { ...dynamic, appearanceMode: "system" },
    true
  ).accent,
  "#334455"
);

// Standalone mode follows light/dark appearance.
assert.equal(
  resolveStandaloneTheme(false).id,
  "paperEmber"
);

assert.equal(
  resolveStandaloneTheme(false).accent,
  "#D65A26"
);

assert.equal(
  resolveStandaloneTheme(true).id,
  "carbonEmber"
);

assert.equal(
  resolveStandaloneTheme(true).accent,
  "#FF8A52"
);

// Invalid CSS must not be applied. Older protocol
// colors remain available as a safe fallback.
const malicious = {
  ...dynamic,
  palettes: {
    ...dynamic.palettes,
    light: {
      ...dynamic.palettes.light,
      accent: "red; background:blue"
    }
  }
};

assert.equal(
  resolveDoItThenTheme(malicious, false).accent,
  "#D65A26"
);

console.log(
  "Dynamic palettes and standalone fallback tests passed"
);

const themeCache = cacheRecordForThemeInfo({
  ...dynamic,
  appearanceMode: "system"
});
assert.equal(themeCache.version, 1);
assert.equal(themeCache.light.colors["--bg"], "#010203");
assert.equal(themeCache.dark.colors["--bg"], "#101112");
assert.equal(
  themeCache.light.colors["--accent"], "#A1B2C3"
);
assert.equal(cacheRecordForThemeInfo(null), null);

const forcedLightCache = cacheRecordForThemeInfo({
  ...dynamic,
  appearanceMode: "light"
});
assert.equal(forcedLightCache.dark.mode, "light");
assert.equal(
  forcedLightCache.dark.colors["--bg"], "#010203"
);

console.log("Instant theme cache tests passed");
