import assert from "node:assert/strict";

import {
  PREFERRED_NATIVE_HOST,
  FALLBACK_NATIVE_HOST,
  createNativeBridge
} from "./native-bridge.js";

function fakeRuntime(steps) {
  let lastError = null;

  return {
    get lastError() {
      return lastError;
    },

    sendNativeMessage(
      host,
      message,
      callback
    ) {
      const step = steps.shift();

      assert.ok(
        step,
        "Unexpected native message"
      );

      assert.equal(
        host,
        step.host
      );

      assert.equal(
        message.action,
        step.action
      );

      lastError =
        step.error
          ? {
              message:
                step.error
            }
          : null;

      callback(
        step.response
      );

      lastError = null;
    }
  };
}

// Preferred Do It Then host is selected.
{
  const runtime =
    fakeRuntime([
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "ping",
        response:
          { ok: true }
      },
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "lists",
        response:
          {
            ok: true,
            lists: []
          }
      }
    ]);

  const bridge =
    createNativeBridge(runtime);

  const response =
    await bridge.sendNativeMessage({
      action: "lists"
    });

  assert.equal(response.ok, true);
  assert.equal(
    bridge.getActiveHostName(),
    PREFERRED_NATIVE_HOST
  );
}

// Missing Do It Then host falls back.
{
  const runtime =
    fakeRuntime([
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "ping",
        error:
          "Specified native messaging host not found."
      },
      {
        host:
          FALLBACK_NATIVE_HOST,
        action:
          "lists",
        response:
          {
            ok: true,
            lists: []
          }
      }
    ]);

  const bridge =
    createNativeBridge(runtime);

  const response =
    await bridge.sendNativeMessage({
      action: "lists"
    });

  assert.equal(response.ok, true);
  assert.equal(
    bridge.getActiveHostName(),
    FALLBACK_NATIVE_HOST
  );
}

// A real error response from Do It Then must
// remain on Do It Then, not silently fall back.
{
  const runtime =
    fakeRuntime([
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "ping",
        response:
          { ok: true }
      },
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "add",
        response:
          {
            ok: false,
            code:
              "reminders_permission_denied",
            error:
              "Reminders access was denied."
          }
      }
    ]);

  const bridge =
    createNativeBridge(runtime);

  const response =
    await bridge.sendNativeMessage({
      action: "add"
    });

  assert.equal(
    response.code,
    "reminders_permission_denied"
  );

  assert.equal(
    bridge.getActiveHostName(),
    PREFERRED_NATIVE_HOST
  );
}

// A running host that crashes is not treated
// as "host unavailable".
{
  const runtime =
    fakeRuntime([
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "ping",
        error:
          "Native host has exited."
      }
    ]);

  const bridge =
    createNativeBridge(runtime);

  await assert.rejects(
    bridge.sendNativeMessage({
      action: "lists"
    }),
    /Native host has exited/
  );

  assert.equal(
    bridge.getActiveHostName(),
    null
  );
}

// Theme info is requested only from the
// preferred Do It Then host.
{
  const runtime =
    fakeRuntime([
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "ping",
        response:
          { ok: true }
      },
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "themeInfo",
        response:
          {
            ok: true,
            available: true,
            schemaVersion: 1,
            appearanceMode: "light",
            lightTheme: "paperEmber",
            darkTheme: "carbonEmber"
          }
      }
    ]);

  const bridge =
    createNativeBridge(runtime);

  const response =
    await bridge
      .getDoItThenThemeInfo();

  assert.equal(
    response.available,
    true
  );
}

// When Do It Then is unavailable, theme
// silently remains System. The standalone
// helper is not asked for themeInfo.
{
  const runtime =
    fakeRuntime([
      {
        host:
          PREFERRED_NATIVE_HOST,
        action:
          "ping",
        error:
          "Specified native messaging host not found."
      }
    ]);

  const bridge =
    createNativeBridge(runtime);

  const response =
    await bridge
      .getDoItThenThemeInfo();

  assert.equal(
    response.available,
    false
  );

  assert.equal(
    bridge.getActiveHostName(),
    FALLBACK_NATIVE_HOST
  );
}

console.log(
  "Native bridge resolver tests passed"
);
