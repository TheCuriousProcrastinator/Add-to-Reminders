<!-- VIBE-CURRENT-STATE:START -->
## Current repository facts (generated, authoritative only for the facts listed)

- Repository: `TheCuriousProcrastinator/Add-to-Reminders`; local working branch: `vibe/chrome-manifest-shortcut-023`.
- Version data below is read from the **Git index** (the files staged for commit).
- Source `chrome-extension/manifest.json`: version `0.2.3`.
- GitHub publication: Published GitHub release `v0.1.4` (reported by GitHub API). Other distribution channels are **unverified**.
- This section does **not** establish local build success, manual QA, App Store/Chrome Web Store approval, notarization, live website deployment, or release-asset integrity.
- The narrative below maintains architecture, decisions, issues and test evidence. Its older status and version claims are **historical** unless explicitly reconciled with this section.
- Before executable changes, inspect the actual checkout and validate the **exact files** on the real Mac. No automatic GitHub Actions.

<!-- VIBE-CURRENT-STATE:END -->

# Add to Reminders - Development Handoff

Last reviewed: 2026-10-28

## Project and Repository

Add to Reminders is a Chrome extension for capturing webpages
directly into Apple Reminders on macOS.

Product principle: Open, edit, save, done.

Repository: `TheCuriousProcrastinator/Add-to-Reminders`

Default branch: `main`

Validated development branch:
`vibe/chrome-manifest-shortcut-023`

Validated source commit:
`cb34cb7dfba587a8db8f43c383c110e90efbcf64`

At this checkpoint:
- Development branch contains extension 0.2.3.
- `main` remains at extension 0.2.2.
- A documentation-only commit may advance development HEAD.
- Verify GitHub state before any future development.

Primary local checkout:
`~/Documents/Vibe Coding/AddToReminders`

Validated development worktree:
`~/Desktop/tmp/Add-to-Reminders-shortcut-023`

The original checkout previously had an unrelated manifest
modification. Its current status remains unverified.
Never automatically reset, stash, or overwrite it.

## Current Version and Distribution

Chrome extension source version: **0.2.3**

Manifest: Chrome Manifest V3

Production Chrome Web Store extension ID:
`nofdmceaajfglgpldmibhggabdjgbgnf`

Development extension ID:
`fdkkbdcnkigfhiabomhklbfapojbpdol`

Final validated package:
`~/Downloads/Add-to-Reminders-0.2.3-Chrome-Web-Store-FINAL.zip`

SHA-256:
`d10894fa6902dd51ecf588a165037c4624d48ee794ad1d4e3ef638d1519a42a6`

Package contents were verified against the committed source.
The development manifest key is excluded from the package.

Chrome Web Store submission and approval of version 0.2.3
remain unverified.

The separate native helper's latest verified GitHub release
is **v0.1.4**, containing `AddToRemindersHelper-0.1.4.pkg`.

The helper version and Chrome extension version are independent.

## Architecture

The repository contains:
- Chrome Manifest V3 extension
- Native macOS helper
- Package builder
- Local regression tests

Important extension files:
- `chrome-extension/manifest.json`
- `chrome-extension/popup.html`
- `chrome-extension/popup.js`
- `chrome-extension/theme-boot.js`
- `chrome-extension/extension-theme.js`
- `chrome-extension/native-bridge.js`
- `chrome-extension/background.js`
- `chrome-extension/options.html`
- `chrome-extension/options.js`
- `chrome-extension/date-parser.js`
- `chrome-extension/project-parser.js`
- `chrome-extension/priority-parser.js`
- `chrome-extension/icons/`

Native helper files:
- `mac-helper/main.swift`
- `mac-helper/RichLink.m`
- `mac-helper/RichLinkBridge.h`
- `build-pkg.command`

The helper uses EventKit to create reminders and a limited
ReminderKit bridge to attach native rich webpage URLs.

Do not replace this with direct Reminders SQLite access,
Full Disk Access, or wholesale private ReminderKit creation.

## Native Messaging

Production Do It Then host:
`com.thecuriousprocrastinator.doitthen.chrome`

Development Do It Then host:
`com.thecuriousprocrastinator.doitthen.chrome.dev`

Standalone fallback helper:
`com.alex.addtoreminders`

The extension selects the host according to extension ID.

Fallback occurs only when the preferred host is unavailable.
Real permission, validation, or save errors must be surfaced.

The extension also sends a lightweight native messaging
check-in to Do It Then.

Do not replace availability detection with Chrome profile
or extension-folder inspection.

## Theme Synchronization

The Chrome extension follows Do It Then's selected appearance
and light/dark theme.

Relevant companion application files:
- `DoItThen/Core/Theme/DoItThenTheme.swift`
- `DoItThen/Core/Theme/ChromeThemeBridgeState.swift`
- `ChromeHost/main.swift`

Chrome components:
- `native-bridge.js` requests themeInfo.
- `extension-theme.js` validates and applies palette values.
- `theme-boot.js` initializes cached theme colors.
- `popup.html` uses CSS theme variables.

Native theme schema version: 1.

The extension supports the app's dynamic color palettes,
with built-in standalone themes when Do It Then is unavailable.

Paper Ember reference:
- Primary accent: `#C64F1A`
- Strong accent: `#AC4111`
- Primary action fill: `#C64F1A`

The Chrome Add Reminder button uses `var(--accent)`.
It must not permanently use `var(--accent-hover)`.

Button styling:
- Solid theme color
- No gradient
- No glossy shadow
- Subtle brightness change on hover

The user visually compared Chrome and Quick Add in 0.2.3.
Their button colors matched in the supplied screenshot.

Not every light/dark theme combination was separately
reconfirmed after the final styling change.

The extension's older standalone fallback colors may differ
from the current application palette. This is a potential
future alignment task, not a confirmed live sync failure.

## Popup UX

Preserve the compact capture interface:
- Page title and website
- List
- Date
- Priority
- Notes
- Add Reminder
- Settings

Title initialization:
- Insert webpage title.
- Append exactly one trailing space.
- Position caret after the space.
- Do not select all automatically.

Keyboard behavior:
- Title Enter submits unless suggestions are active.
- Notes Enter inserts a newline.
- Notes Command+Enter submits.
- Arrow keys navigate list suggestions.
- Escape dismisses suggestions before closing the popup.

Default capture settings:
- List: Last used
- Date: No date
- Priority: None
- Smart date recognition: On

Settings auto-save.

Typed smart commands override defaults temporarily.
Removing a token restores the prior/default value.

## Smart Parsing

Main files:
- `date-parser.js`
- `project-parser.js`
- `priority-parser.js`

Priority shorthand:
- p1: High, EventKit 1
- p2: Medium, EventKit 5
- p3: Low, EventKit 9
- p4: None, EventKit 0

List examples:
`/Work`, `/Errands`, `/Personal`

List suggestions prioritize prefix matches, then contains
matches, and show up to seven suggestions.

Date parsing includes:
- Today, tomorrow and weekday names
- Weekends, next week/month/year
- Relative minutes, hours, days, weeks and months
- Named dates, ordinals and month positions
- Explicit and natural-language times
- Morning, afternoon, evening and night
- Relative date arithmetic
- Explicit `no date` / `no due date`
- Recurrence expressions

Dayparts:
- Morning 09:00
- Afternoon 12:00
- Evening 19:00
- Night 22:00

Recurrence includes:
- Every weekday
- Selected weekdays
- Every other Monday
- Every N days/weeks/months/years
- Daily, weekly, monthly, quarterly and yearly

Preserve multi-token parsing, highlighting, click-to-reject,
rejected-token range tracking, and default restoration.

`Meet Tom Hanks` must not interpret Tom as tomorrow.

Do not introduce ambiguous numeric dates or completion-relative
`every!` recurrence without a new decision.

## Version 0.2.3 Changes

Chrome Web Store violation:
Yellow Magnesium, minimum functionality.

Reported cause:
Missing default keyboard shortcut key specification.

Fix:
- Added `default: Alt+Shift+R`.
- Preserved `mac: Alt+Shift+R`.
- Kept extension permissions unchanged.

Popup fixes:
- Restored the missing `theme-boot.js`.
- Fixed the blank popup caused by its absence.
- Removed the reversed-gradient button hover.
- Replaced the wrong strong-accent button fill with
  the primary theme accent.

Tests:
- JavaScript syntax checks passed.
- Date parser regression tests passed.
- Native bridge tests passed.
- Theme mapping tests passed.
- Chrome package dependency checks passed.
- Package contents matched the validated source.

Manual evidence:
- User confirmed initial shortcut validation passed.
- User showed the corrected, visible popup.
- User confirmed visual button color alignment.
- User requested commit and packaging.

Not separately reconfirmed after the final styling patch:
- Full end-to-end reminder save
- All available theme combinations
- Production Chrome Web Store behavior

Do not overstate validation.

## Important Historical Findings

- Earlier packages accidentally included backup files.
- An earlier clean package omitted `project-parser.js`.
- Version 0.2.3 initially missed `theme-boot.js`, causing
  a completely blank popup.
- Every package must include its runtime dependencies.
- The source manifest retains the development extension key.
- Web Store packages must remove that key.
- Production and development native hosts remain isolated.
- The installed Chrome 0.2.2 runtime was reconciled into GitHub
  on 2026-10-19.
- Chrome Web Store 0.2.1 was previously submitted.
  Its final review result was not verified here.
- Earlier 0.1.x history remains available through Git.

## Build and Validation

Normal validation is local on the user's actual Mac.

Regression tests:
- `chrome-extension/test-date-parser.mjs`
- `chrome-extension/test-native-bridge.mjs`
- `chrome-extension/test-extension-theme.mjs`

Check JavaScript syntax and `git diff --check`.

Packaging requirements:
- Use an explicit runtime file list.
- Include all referenced scripts and imported local modules.
- Include required icons.
- Exclude tests, backups and temporary artifacts.
- Remove the development manifest key from the ZIP only.
- Confirm package contents against validated source.
- Verify final ZIP integrity and SHA-256.

Increment the extension version for future executable changes.

Manual regression:
- Popup opens normally.
- Keyboard shortcut opens the popup.
- List/date/priority defaults restore correctly.
- Smart date recognition toggle works.
- `tomorrow p1 /Errands` resolves correctly.
- Explicit `no date` overrides a default Today.
- Reminder creation saves the intended fields.
- Native rich webpage URL is attached.
- Theme synchronization matches Do It Then.
- Production and development hosts remain isolated.

The helper's Universal 2 package is built with
`build-pkg.command` when helper changes require it.

## Deferred Features

Do not add without an explicit user decision:
- Full Reminders client
- Tags, image attachments or OCR
- AI scanning
- Assignees or duration
- Hourly recurrence
- Completion-relative recurrence
- Extra Chrome permissions
- Direct Reminders database access

Potential future features:
- Instant capture
- Reminder alarm syntax
- Recurrence ending constraints
- Multi-reminder paste

## Separate QuickAdd Project

Standalone QuickAdd is not part of this repository.

GitHub:
`TheCuriousProcrastinator/QuickAdd-for-Reminders`

Local path:
`~/Documents/Vibe Coding/QuickAdd`

The Do It Then app is another separate repository.

## Development Rules

Before modifying a local checkout:
1. Fetch origin.
2. Verify branch and expected HEAD.
3. Inspect `git status --short`.
4. Stop if unrelated changes exist.
5. Inspect implementation before editing.

Do not automatically reset, stash, merge or overwrite changes.

For executable changes:
- Use the smallest reliable patch.
- Test the exact files on the user's Mac.
- Require explicit manual confirmation for UI behavior.
- Update this handoff.
- Commit only validated files.
- Push the correct branch.
- Verify remote HEAD.

GitHub Actions policy:
- Manual `workflow_dispatch` only.
- Never run automatically for pushes, PRs or tags.
- Do not use Actions for normal development validation.

The tracked `.githooks/pre-commit` invokes
`Tools/vibe_handoff.py sync-staged`.

It updates the generated current-state section.
It does not replace the manually maintained handoff narrative.

Documentation-only handoff changes do not require rebuilding.

Temporary worktrees and build artifacts belong under
`~/Desktop/tmp/`.

Do not remove an active development worktree or Chrome profile.

## Current Open Items

1. Verify whether 0.2.3 was submitted to Chrome Web Store.
2. Verify approval/publication when Google completes review.
3. Test production reminder creation and theme synchronization.
4. Reconcile the validated development branch with `main`
   when authorized.
5. Preserve unrelated local checkout modifications.

No new feature is authorized by this handoff alone.

## Prompt for the Next ChatGPT Session

Read the full handoff first.

Treat it as historical context, then independently verify
repository, branches, HEAD, manifest version, source files,
release state, and Chrome Web Store publication.

Do not guess about implementation details.

Preserve existing behavior, the local validation requirement,
and manual-only GitHub Actions policy.
