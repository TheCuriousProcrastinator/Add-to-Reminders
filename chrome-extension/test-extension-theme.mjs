import assert from "node:assert/strict";

import {
  resolveDoItThenTheme,
  cssVariablesForTheme
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
