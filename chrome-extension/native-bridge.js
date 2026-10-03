export const PREFERRED_NATIVE_HOST =
  "com.thecuriousprocrastinator.doitthen.chrome";

export const FALLBACK_NATIVE_HOST =
  "com.alex.addtoreminders";

export function isNativeHostUnavailableError(
  error
) {
  const message =
    String(
      error?.message ||
      error ||
      ""
    ).toLowerCase();

  return (
    message.includes(
      "specified native messaging host not found"
    ) ||
    message.includes(
      "native messaging host not found"
    ) ||
    message.includes(
      "access to the specified native messaging host is forbidden"
    ) ||
    message.includes(
      "failed to start native messaging host"
    )
  );
}

export function createNativeBridge(runtime) {
  let activeHostName = null;

  function sendToHost(
    hostName,
    message
  ) {
    return new Promise(
      (resolve, reject) => {
        runtime.sendNativeMessage(
          hostName,
          message,
          response => {
            const runtimeError =
              runtime.lastError;

            if (runtimeError) {
              reject(
                new Error(
                  runtimeError.message
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

  async function selectHost() {
    if (activeHostName) {
      return activeHostName;
    }

    try {
      const response =
        await sendToHost(
          PREFERRED_NATIVE_HOST,
          {
            action: "ping"
          }
        );

      if (!response?.ok) {
        throw new Error(
          response?.error ||
          "Do It Then Chrome host ping failed."
        );
      }

      activeHostName =
        PREFERRED_NATIVE_HOST;

    } catch (error) {
      if (
        !isNativeHostUnavailableError(
          error
        )
      ) {
        throw error;
      }

      activeHostName =
        FALLBACK_NATIVE_HOST;
    }

    return activeHostName;
  }

  async function sendNativeMessage(
    message
  ) {
    const hostName =
      await selectHost();

    try {
      return await sendToHost(
        hostName,
        message
      );

    } catch (error) {
      if (
        hostName ===
          PREFERRED_NATIVE_HOST &&
        isNativeHostUnavailableError(
          error
        )
      ) {
        activeHostName =
          FALLBACK_NATIVE_HOST;

        return await sendToHost(
          activeHostName,
          message
        );
      }

      throw error;
    }
  }

  async function getDoItThenThemeInfo() {
    const hostName =
      await selectHost();

    if (
      hostName !==
      PREFERRED_NATIVE_HOST
    ) {
      return {
        ok: true,
        available: false,
        schemaVersion: 1
      };
    }

    try {
      return await sendToHost(
        hostName,
        {
          action: "themeInfo"
        }
      );

    } catch (error) {
      if (
        isNativeHostUnavailableError(
          error
        )
      ) {
        activeHostName =
          FALLBACK_NATIVE_HOST;

        return {
          ok: true,
          available: false,
          schemaVersion: 1
        };
      }

      throw error;
    }
  }

  return {
    sendNativeMessage,
    getDoItThenThemeInfo,

    getActiveHostName() {
      return activeHostName;
    }
  };
}

let defaultBridge = null;

function getDefaultBridge() {
  if (!defaultBridge) {
    defaultBridge =
      createNativeBridge(
        chrome.runtime
      );
  }

  return defaultBridge;
}

export function sendNativeMessage(
  message
) {
  return getDefaultBridge()
    .sendNativeMessage(
      message
    );
}


export function getDoItThenThemeInfo() {
  return getDefaultBridge()
    .getDoItThenThemeInfo();
}
