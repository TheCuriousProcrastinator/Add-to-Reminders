# Add to Reminders

A Chrome extension that sends the webpage you're viewing directly to Apple Reminders on your Mac.

## What it does

- Saves the current page title and URL to Apple Reminders
- Lets you choose a Reminders list
- Supports dates, times, recurrence, priority, and notes
- Understands shortcuts like `tom at noon`, `fri 3pm`, and `/Work`
- Can send selected text from Chrome's right-click menu
- Adds the webpage as a native clickable link in Reminders

## Requirements

- macOS 14 or later
- Google Chrome
- Apple Reminders

A small Mac helper is required because Chrome extensions cannot write directly to Apple Reminders.

## Mac Helper

Download the latest helper from:

https://github.com/TheCuriousProcrastinator/Add-to-Reminders/releases/latest

Open the `.pkg` and follow the installer.

The helper currently is not signed with an Apple Developer ID. macOS may block it the first time. If that happens, open:

**System Settings > Privacy & Security**

and approve the installer with **Open Anyway**.

The helper runs locally on your Mac and communicates with the Chrome extension using Chrome Native Messaging.

## Privacy

Website information and reminder data are processed locally on your Mac.

The extension does not send your browsing data, reminder data, or personal information to the developer or third-party servers.

See [PRIVACY.md](PRIVACY.md) for details.

## Source

The Chrome extension and Mac helper are available in this repository.

The separate QuickAdd macOS app is not part of this repository.
