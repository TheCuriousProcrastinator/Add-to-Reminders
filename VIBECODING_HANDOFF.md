# VIBECODING_HANDOFF.md

## Project

**Name:** Add to Reminders

**Purpose:** macOS-only Chrome extension for fast Todoist-style capture into Apple Reminders.

Product philosophy:

> Open -> type/edit -> Enter -> gone.

This is intentionally a capture utility, not a full Apple Reminders client.

The project has two components in this repository:

1. Chrome extension
2. Native macOS helper connected through Chrome Native Messaging

A separate native QuickAdd app exists in another repository and must not be mixed into this repo.

## Repository and local paths

- GitHub: `TheCuriousProcrastinator/Add-to-Reminders`
- Repository visibility: public
- Default branch: `main`
- Current active branch at handoff creation: `main`
- Only branch present in GitHub at handoff creation: `main`
- Code HEAD before this handoff-only commit: `652b277116c1e18796169f5b86784bf5c5355511`
- Latest code commit before handoff: `Add capture settings and expanded date language`
- Local project path: `/Users/alex/Documents/Vibe Coding/AddToReminders`
- Chrome extension path: `/Users/alex/Documents/Vibe Coding/AddToReminders/chrome-extension`
- Native helper path: `/Users/alex/Documents/Vibe Coding/AddToReminders/mac-helper`
- Package builder: `/Users/alex/Documents/Vibe Coding/AddToReminders/build-pkg.command`
- Local distribution directory: `/Users/alex/Documents/Vibe Coding/AddToReminders/dist`

Because this file is committed after the code HEAD above, always verify the actual current GitHub HEAD before changing anything.

## Current version and release state

### Chrome extension

Verified in `chrome-extension/manifest.json` on `main`:

- Manifest V3
- source version: **0.1.14**
- store/listing name in manifest: `Add Website to Reminders`
- action title: `Add to Reminders`
- default popup: `popup.html`
- options page: `options.html`
- keyboard command: `Alt+Shift+R` on macOS
- development manifest intentionally contains a `"key"` to keep the unpacked extension ID stable

Current source permissions:

- `activeTab`
- `storage`
- `nativeMessaging`
- `contextMenus`

No host permissions are present in the current manifest.

### Helper release

Latest verified GitHub Release:

- tag: **v0.1.4**
- name: `Add to Reminders Helper 0.1.4`
- asset: `AddToRemindersHelper-0.1.4.pkg`
- SHA-256: `43aa22cdb6ad26b103024c4a9eeb21a81db7c9ebcd92bdb2d4037d454eb8a524`
- macOS 14+
- Universal 2
- ad-hoc signed, not Developer ID signed
- installs Native Messaging support for regular Chrome and Chrome for Testing

### Chrome Web Store

Historical handoff states:

- Web Store version 0.1.5 was approved on 2026-08-31.
- The previous chat did not verify whether 0.1.5 was manually published.

GitHub cannot verify Chrome Web Store publication state. Treat current Approved/Published status as **unverified** until checked directly in the Chrome Web Store dashboard.

## Separate QuickAdd project

Do not mix the standalone QuickAdd app into this repository.

Separate local path:

`/Users/alex/Documents/Vibe Coding/QuickAdd`

Separate GitHub repository:

`TheCuriousProcrastinator/QuickAdd-for-Reminders`

The Chrome extension parser has intentionally borrowed/paralleled some QuickAdd parsing behavior, but the apps remain separate projects.

## Architecture

### Chrome extension

Current runtime source files in GitHub:

- `chrome-extension/manifest.json`
- `chrome-extension/popup.html`
- `chrome-extension/popup.js`
- `chrome-extension/background.js`
- `chrome-extension/date-parser.js`
- `chrome-extension/project-parser.js`
- `chrome-extension/priority-parser.js`
- `chrome-extension/options.html`
- `chrome-extension/options.js`
- `chrome-extension/test-date-parser.mjs`
- `chrome-extension/icons/`

The extension uses Chrome Native Messaging host:

`com.alex.addtoreminders`

### Native helper

Relevant files:

- `mac-helper/main.swift`
- `mac-helper/RichLink.m`
- `mac-helper/RichLinkBridge.h`
- `mac-helper/Info.plist`
- `build-pkg.command`

The helper uses:

- EventKit for Apple Reminders access and reminder creation
- a small private ReminderKit bridge only for attaching the native rich URL/source link
- Chrome Native Messaging over stdin/stdout

Do not casually replace this hybrid architecture.

Historical failed/rejected approaches that should not be revived without a strong reason:

- Full Disk Access
- direct Reminders SQLite access
- full private ReminderKit reminder creation
- tags
- image attachments

## Native helper design

Verified current helper behavior includes:

- request full Reminders access through EventKit
- enumerate reminder lists
- create reminder lists
- parse date/time payloads
- construct EventKit recurrence rules
- create reminders from Native Messaging requests
- use `RichLink.m` to locate the EventKit-created reminder through ReminderKit and attach a native URL attachment

`RichLink.m` dynamically loads:

`/System/Library/PrivateFrameworks/ReminderKit.framework/ReminderKit`

It finds the created reminder by its calendar identifier, updates it through `REMSaveRequest`, and adds a URL attachment.

This private-framework bridge is deliberate and should be handled carefully.

## Helper packaging

`build-pkg.command` currently:

- reads the package version from `chrome-extension/manifest.json`
- builds arm64 helper
- builds x86_64 helper
- creates a Universal 2 binary with `lipo`
- targets macOS 14
- creates `AddToRemindersHost.app`
- ad-hoc signs the app
- creates Native Messaging manifests for:
  - `/Library/Google/Chrome/NativeMessagingHosts/`
  - `/Library/Google/ChromeForTesting/NativeMessagingHosts/`
- packages output into `dist/AddToRemindersHelper-<version>.pkg`
- removes metadata junk before packaging

Production Chrome extension origin currently allowed by the packaged Native Messaging manifest:

`chrome-extension://nofdmceaajfglgpldmibhggabdjgbgnf/`

## Chrome extension IDs

Historical handoff values, consistent with current packaging/source:

Development unpacked extension ID:

`fdkkbdcnkigfhiabomhklbfapojbpdol`

Chrome Web Store production ID:

`nofdmceaajfglgpldmibhggabdjgbgnf`

Important:

- the working development `manifest.json` intentionally contains a `"key"`
- do not remove that key from source
- remove it only from a copied production manifest when building a Web Store package

## Popup UX

The current popup is intentionally compact and should not be broadly redesigned unless requested.

Current intended layout and behavior:

- about 360px wide
- dark/light aware
- compact macOS-inspired visual density
- app icon + Add to Reminders header
- Settings gear
- title field
- site/domain
- List
- Date
- Priority
- Notes
- Add Reminder CTA

Title behavior is intentional:

- webpage title is inserted automatically
- exactly one trailing space is appended
- caret is placed after that space
- title is not select-all highlighted

Do not restore select-all behavior.

## Keyboard behavior

Current intended behavior:

- Title Enter submits reminder unless `/List` suggestions are active
- Notes Enter inserts newline
- Notes Command+Enter submits
- `/List` suggestions use Arrow Up/Down and Enter
- Escape closes `/List` suggestions first
- Escape again closes the popup

## Capture settings

Verified current code contains capture settings in `popup.js` and `options.js`.

Current defaults:

- Default list: `Last used`
- Default date: `No date`
- Default priority: `None`
- Smart date recognition: On

Settings auto-save.

List ordering rule:

1. `Last used`
2. `Inbox`
3. other Apple Reminders lists alphabetically

Typed smart commands override defaults while present. Removing those tokens restores the prior/default values.

Example:

Defaults:
- Inbox
- Today
- Medium

Typing:

`tomorrow p1 /Errands`

should resolve to:

- Tomorrow
- High
- Errands

Deleting the tokens should restore:

- Today
- Medium
- Inbox

This restoration behavior is important.

## Smart list parsing

Parser:

`chrome-extension/project-parser.js`

Supported examples include:

- `/Work`
- `/Errands`
- `/Personal`

Expected behavior:

- matches real Apple Reminders lists
- suggestions prioritize starts-with then contains
- maximum 7 suggestions
- smart list token is highlighted
- token is removed before save
- smart list overrides current/default list while present
- deleting token restores prior/default list

## Priority parsing

Parser:

`chrome-extension/priority-parser.js`

Mappings:

- `p1` -> High -> EventKit value 1
- `p2` -> Medium -> EventKit value 5
- `p3` -> Low -> EventKit value 9
- `p4` -> None -> EventKit value 0

Typed priority overrides the default while present. Removing it restores the previous/default priority.

## Natural-language date parser

Main file:

`chrome-extension/date-parser.js`

The parser is deliberately more than a single-match regex. Preserve its multi-token architecture.

Important current capabilities from source and prior verified work include:

### Basic dates

- today / tod
- tomorrow / tom / tmr
- tonight
- weekday names
- next weekday
- weekend / this weekend / next weekend
- next week
- next month
- next year

Short aliases are deliberately conservative.

Example:

`Meet Tom Hanks`

must not interpret `Tom` as tomorrow.

### Relative dates

- in 20 minutes
- in N hours
- in N days
- in a week
- in N weeks
- in a month
- in N months
- optional explicit times

Month arithmetic clamps to valid dates.

### Times

- noon
- 4pm
- 4:30pm
- 16:00
- 1600

Bare time rolls to tomorrow if already passed. Explicit date + time should not silently roll the date.

### Dayparts

Source marker: `TODOIST_DATE_LANGUAGE_V014`

Current dayparts include:

- morning -> 09:00
- afternoon -> 12:00
- evening -> 19:00
- night -> 22:00

Examples:

- `tom morning`
- `tom afternoon`
- `tom evening`
- `tom night`
- `in the morning`
- `in the afternoon`
- `in the evening`
- `in the night`

### Named dates

Examples:

- Jan 27
- January 27
- 27 Jan
- 27 January
- Jan 27 2027
- January 27, 2027
- 27 Jan 2027
- 27 January 2027

Impossible dates must be rejected.

### Additional date language

Supported/intended behavior includes:

- ordinal day of month such as `27th`
- `mid January`
- `end of month`
- plus-relative forms such as `+3 weeks`
- arithmetic such as `6 weeks before 21 Jul`
- ordinal weekday of month such as `3rd Friday of September`
- `last Friday of November`
- explicit `no date` and `no due date`

Do not add ambiguous numeric date forms such as `27/1` unless explicitly requested.

## Recurrence

Current parser supports a broad recurrence grammar.

Examples include:

- every weekday
- every workday
- every weekend
- every mon, fri
- ev mon, wed, fri 3pm
- every Monday
- every Fri at 16:00
- every other Monday
- every 3rd Friday
- every last Friday
- every 3 days
- every 2 weeks
- every 4 months
- every 2 years
- every other day/week/month/year
- daily
- weekly
- monthly
- yearly
- quarterly
- every quarter
- every 27th

`ev` is a supported shorthand for `every`.

Explicitly deferred:

`every! 3 days`

Completion-relative recurrence was intentionally not implemented.

## Multi-token parsing

Preserve this architecture.

Current popup parsing supports:

- separate date and time smart tokens
- token ranges
- smart highlighting
- click-to-reject recognized date tokens
- rejected-token range shifting as title text changes
- stronger date phrase winning over ambiguous aliases
- smart token removal before save
- rejected tokens remaining literal

Do not replace this with a simplistic parser without understanding these behaviors.

## Explicit no-date syntax

Supported:

- `no date`
- `no due date`

This exists because Settings can define a default date.

If the default is Today:

- typing `no date` must switch to No date
- deleting the token must restore Today
- an independent time token must not create a due date while `no due date` is active

## Packaging rules

Local `.gitignore` deliberately ignores:

- `*.before-*` temporary backups
- `dist/`
- helper build products
- separate QuickAdd project

Do not package the entire local `chrome-extension` directory blindly.

Historical packaging bugs already encountered:

- backup `.before-*` files accidentally entered a ZIP
- a clean ZIP accidentally omitted `project-parser.js`

Production Web Store packages must be built from an explicit runtime whitelist.

Expected runtime whitelist:

- `manifest.json`
- `popup.html`
- `popup.js`
- `background.js`
- `date-parser.js`
- `project-parser.js`
- `priority-parser.js`
- `options.html`
- `options.js`
- `icons/icon16.png`
- `icons/icon32.png`
- `icons/icon48.png`
- `icons/icon128.png`
- `icons/icon512.png`

Before packaging:

- run `git diff --check`
- syntax-check JavaScript
- run parser regressions
- verify all imported local JS modules exist in package
- copy manifest and remove only the packaged `"key"`
- verify the exact whitelist
- final ZIP goes into local `dist/`

Do not use `/tmp` as the final Web Store artifact location.

Naming convention:

`AddToReminders-<version>-webstore.zip`

## Versioning rule

**Every development change/test build must bump the Chrome extension version.**

This includes:

- UI changes
- parser changes
- keyboard changes
- Settings changes
- small bug fixes

Do not leave changed extension code on the same manifest version.

A documentation-only handoff commit does not require an extension version bump.

## Validation

There is currently **no `.github/workflows` directory and no GitHub Actions workflow** in the repo.

Validation is therefore local/manual unless a workflow is added later.

Current lightweight parser script:

`chrome-extension/test-date-parser.mjs`

Run from the Chrome extension directory with Node.

Recommended baseline checks before a code commit:

```bash
git diff --check
node --check chrome-extension/background.js
node --check chrome-extension/popup.js
node --check chrome-extension/options.js
node --check chrome-extension/date-parser.js
node --check chrome-extension/project-parser.js
node --check chrome-extension/priority-parser.js
node chrome-extension/test-date-parser.mjs
```

For helper changes, also build/package with `build-pkg.command` and verify the generated Universal 2 package.

## Critical regression checks before a store release

### Defaults and restoration

Set:

- Default List = Inbox
- Default Date = Today
- Default Priority = Medium

Type:

`tomorrow p1 /Errands`

Expected:

- Tomorrow
- High
- Errands

Delete tokens one at a time and verify defaults restore.

### No-date override

With default Today:

`no date`

Expected: No date.

Delete it: Today should restore.

### Smart recognition toggle

With Smart date recognition OFF, these remain literal:

- tomorrow
- Jan 27
- 6pm
- +3 weeks

These still work:

- p1
- /Errands

### Parser regression examples

Existing behavior worth preserving:

- tomorrow noon
- noon tomorrow
- Friday 3pm
- next Monday
- in 20 minutes
- in a week at noon
- every weekday at 9am
- ev mon, wed, fri 3pm
- every other Monday
- every 3 days
- quarterly
- every 27th
- Meet Tom Hanks

Newer date-language examples:

- tom morning
- tom afternoon
- tom evening
- tom night
- next year
- Jan 27
- 27 Jan
- 27th
- mid January
- end of month
- +3 weeks
- no date
- 6 weeks before 21 Jul
- 28 days after 21 July

### Actual Apple Reminders output

Verify end-to-end on macOS:

- smart tokens stripped from title
- native rich URL attached
- correct list
- correct due date/time
- correct recurrence
- correct priority
- notes preserved

## Chrome Web Store history

Historical handoff records:

- version 0.1.3 was rejected for "Not providing promised functionality"
- Chrome for Testing Native Messaging support was then added
- helper v0.1.4 installs manifests for regular Chrome and Chrome for Testing
- Chrome Web Store version 0.1.5 was approved on 2026-08-31

Current publication state is unverified.

Do not replace or publish a store draft without checking the current dashboard first.

## Important UX and product decisions

- Keep the app focused on fast capture.
- Do not turn it into a full Reminders client.
- Avoid new Chrome permissions unless clearly necessary.
- Preserve the current compact popup unless redesign is explicitly requested.
- Preserve automatic title insertion with one trailing space and caret at the end.
- Preserve parser restoration behavior when smart tokens are removed.
- Preserve multi-token parser architecture.
- Keep QuickAdd separate.
- Keep rich-link helper architecture unless there is a verified better path.

## Features explicitly not wanted right now

Do not add without an explicit new decision:

- full Apple Reminders client/sidebar
- attachments
- OCR/image extraction
- AI document scanning
- assignees
- duration fields
- hourly recurrence
- completion-relative `every!`
- unnecessary permissions
- Full Disk Access
- direct Reminders SQLite access
- tags

## Potential future features

Historical candidates only. Do not start automatically:

1. Instant Capture / Quick Save without opening popup
2. reminder alarm syntax such as `!30m before`
3. recurrence `starting`, `until`, `for N`
4. multi-reminder paste

The user should choose the next feature after current state is verified.

## Fixed / known historical bugs

Fixed:

- Chrome for Testing Native Messaging support
- missing package dependency `project-parser.js`
- package contamination by development backups
- popup/Settings consistency work
- parser parity and expanded date language
- fixed/default capture settings and restoration behavior
- QuickAdd removed from this repository into a separate repo

Open/unverified:

- Chrome Web Store 0.1.5 current publication status
- whether a local `dist/AddToReminders-0.1.14-webstore.zip` currently exists, because `dist/` is ignored and cannot be verified from GitHub
- local working-tree cleanliness cannot be verified from GitHub
- no current GitHub Actions validation exists

## Exact next development task

Before changing code:

1. Verify local checkout matches GitHub `main`.
2. Verify local manifest version is 0.1.14.
3. Inspect local `dist/` contents.
4. Check Chrome Web Store dashboard for the current published/draft state.
5. Run baseline JS/parser validation.
6. Ask the user which next feature or bug to work on if none is specified.

Do not assume the historical 0.1.14 Web Store package exists just because source version 0.1.14 is in GitHub.

## Suggested local state check

```bash
cd "/Users/alex/Documents/Vibe Coding/AddToReminders" || exit 1
set -e
export GIT_PAGER=cat

git fetch origin
git switch main
git pull --ff-only origin main

printf '===== VERSION =====\n'
python3 -c 'import json; print(json.load(open("chrome-extension/manifest.json"))["version"])'

printf '\n===== GIT =====\n'
git status --short
git --no-pager log -5 --oneline --decorate

printf '\n===== DIST =====\n'
find dist -maxdepth 1 -type f -print 2>/dev/null | sort || true
```

## Handoff maintenance rule

Every meaningful future development commit must update this file with enough context for a fresh ChatGPT session to continue without prior conversation context.

Update this handoff whenever a commit changes:

- feature behavior
- bug behavior
- architecture
- important implementation decisions
- version/build/release state
- debugging findings
- validation/test status
- known issues
- exact next task

Keep it current-state focused rather than chronological.

Documentation-only commits that do not affect development context do not need to change the product version.

## Prompt for the next ChatGPT session

Read the full handoff first.

Treat it as historical context, but verify the current GitHub repository, branch, HEAD, extension version, helper release state, and relevant source before making changes.

Identify meaningful differences between the handoff and the current code.

Never guess about implementation details that can be inspected.

Preserve existing working behavior and continue from the current verified state.


<!-- VIBE-CI-POLICY-2026-09-30 -->
## Local validation and GitHub Actions policy

This section is authoritative and supersedes older CI wording elsewhere in this handoff.

- Normal development is validated in the user's actual local checkout before any GitHub write.
- Only the exact locally tested files may be committed and pushed.
- GitHub Actions is not the routine development validation loop.
- Ordinary feature-branch pushes, ordinary `main` pushes, and pull requests must not automatically trigger GitHub Actions.
- If a GitHub Actions workflow exists, it may run only when explicitly started with `workflow_dispatch` or from a release/version tag such as `v1.0.2`.
- Do not broaden automatic CI triggers without the user's explicit approval.
- Use the project's existing local build/test process before committing. For Xcode projects, use `xcodebuild` unless the project specifies otherwise, and leave the freshly built development app running for manual testing when relevant.
- UI, interaction, layout, animation, drag/drop, focus, persistence, timing, and similar behavior changes require explicit user confirmation after local testing.
- A documentation-only handoff update does not require rebuilding.
- Release requests still require the executable behavior to have passed the required local validation first. Once that has happened, do not ask for another manual PASS solely because the release version/build changed or because a final Release build was produced.

### Release / publish authorization

This section is authoritative and supersedes older release-confirmation wording elsewhere in this handoff.

When the user says **release**, **publish**, **make update**, or equivalent, treat that as authorization to complete the full release workflow without an additional publication confirmation.

After the underlying executable change has already passed required local validation, continue automatically through every applicable release step:

- verify the current clean local checkout and release baseline
- bump version/build as required
- build and validate the final Release configuration
- create the final package/ZIP and perform signing/package checks where applicable
- commit and push the validated release changes
- create and push the release/version tag
- allow release-tag GitHub Actions validation to run when configured, and verify it succeeds
- publish GitHub release(s) and downloadable assets
- update the appcast/update feed or other upgrade metadata where applicable
- verify the public release asset and live upgrade/update path
- update this handoff to the final verified release state
- launch or install the final released build when appropriate

A version/build bump, packaging step, signing step, generated appcast/feed change, or final Release-configuration build does **not** by itself require another manual user approval if the executable behavior being released already passed local validation.

Stop only for a genuine blocker, a failed validation that requires an executable behavior change, or an authorization/credential action that only the user can perform. If release preparation introduces a new executable or build-affecting behavior change beyond what was already validated, the local validation gate reopens before publication.

---

<!-- validated-doitthen-native-resolver-2026-10-02 -->

## Validated Do It Then Native Messaging resolver - 2026-10-02

This exact Chrome extension change was tested locally against the real Do It Then development build before commit.

### Version

Extension development version:

`0.1.15`

Previous version:

`0.1.14`

### Native Messaging resolver

New file:

`chrome-extension/native-bridge.js`

Preferred host:

`com.thecuriousprocrastinator.doitthen.chrome`

Existing standalone fallback host:

`com.alex.addtoreminders`

Behavior:

1. The extension probes the Do It Then host with `ping`.
2. If that host is genuinely unavailable, the extension falls back to the existing standalone Add to Reminders helper.
3. The selected host is cached for the lifetime of the popup/options page.
4. If the Do It Then host launches and returns a real permission, validation, or save error, the extension does not silently fall back.
5. If an already-selected preferred host later becomes unavailable, the current request may retry through the standalone host.

Popup and Settings now share this resolver.

### Files

Validated executable/source changes:

- `chrome-extension/manifest.json`
- `chrome-extension/popup.js`
- `chrome-extension/options.html`
- `chrome-extension/options.js`
- `chrome-extension/native-bridge.js`
- `chrome-extension/test-native-bridge.mjs`

`options.html` now loads `options.js` as a module so it can import the shared resolver.

### Automated validation PASS

Validated locally:

- extension version is `0.1.15`
- JavaScript syntax checks passed
- existing date parser regression suite passed
- new Native Messaging resolver regression suite passed
- preferred Do It Then host selection passed
- unavailable preferred-host fallback passed
- permission/error response does not trigger fallback
- a running host that exits is not misclassified as an unavailable installation

### Real Chrome validation PASS

The unpacked development extension was loaded from:

`/Users/alex/Documents/Vibe Coding/AddToReminders-doitthen-dev/chrome-extension`

Development extension ID:

`fdkkbdcnkigfhiabomhklbfapojbpdol`

Validated in Chrome:

- extension correctly shows version `0.1.15`
- Apple Reminders lists load through the Do It Then host
- reminder creation succeeds
- Settings Default List loads
- smart date behavior works
- `/List` behavior works
- priority syntax such as `p1` works

The existing Web Store extension remains separate and unchanged.

### Do It Then regression PASS

Validated against the current Do It Then development branch:

`vibe/chrome-theme-bridge`

Do It Then HEAD used for this test:

`27fcede867bcfbe11aa9134fe184e9f57d234871`

Validated:

- app launches normally
- Calendar loads
- Reminders load
- Global Quick Add saves normally

### Development Native Messaging registration

For local validation, the preferred host was registered at the user level for Chrome and Chrome for Testing and pointed directly at the freshly built Do It Then development host.

This registration was a local development setup step only.

No production `/Library` Native Messaging registration was added in this extension commit.

### Important existing fallback behavior

The standalone helper remains supported and must not be removed.

The extension must continue to work for users who do not have Do It Then installed.

### Exact next task

Implement extension theme following through the preferred Do It Then host:

- request `themeInfo`
- when Do It Then is available, apply its selected appearance/theme palette
- when Do It Then is unavailable, use normal System appearance
- do not add an independent extension theme selector
- preserve standalone helper fallback behavior

Do not begin production installer/registration changes until the extension theme behavior is locally validated.

GitHub remains read-only for each subsequent executable change until that exact change passes local validation.
