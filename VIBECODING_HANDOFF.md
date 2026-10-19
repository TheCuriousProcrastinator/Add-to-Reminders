<!-- VIBE-CURRENT-STATE:START -->
## Current repository facts (generated, authoritative only for the facts listed)

- Repository: `TheCuriousProcrastinator/Add-to-Reminders`; local working branch: `vibe/date-menu-theme-20261019-155757-12032`.
- Version data below is read from the **Git index** (the files staged for commit).
- Source `chrome-extension/manifest.json`: version `0.2.1`.
- GitHub publication: Published GitHub release `v0.1.4` (reported by GitHub API). Other distribution channels are **unverified**.
- This section does **not** establish local build success, manual QA, App Store/Chrome Web Store approval, notarization, live website deployment, or release-asset integrity.
- The narrative below maintains architecture, decisions, issues and test evidence. Its older status and version claims are **historical** unless explicitly reconciled with this section.
- Before executable changes, inspect the actual checkout and validate the **exact files** on the real Mac. No automatic GitHub Actions.

<!-- VIBE-CURRENT-STATE:END -->

## 2026-10-19 - Primary accent consistency

- User explicitly confirmed local development validation: PASS.
- Exact locally tested checkout: `/Users/alex/Documents/Vibe Coding/.vibe-validation/Extension-20261019-155757-12032`.
- Development branch: `vibe/date-menu-theme-20261019-155757-12032`.
- Starting HEAD: `96cf66a2b679904fe07f72dcfb12ae7b950e6f4d`.
- Source changes: `chrome-extension/extension-theme.js`, `chrome-extension/popup.html`, and `chrome-extension/test-extension-theme.mjs`.
- Mint Candy fallback accent text is now white.
- Add Reminder uses a solid theme accent instead of the previous gradient, with a stronger hover state.
- Existing dynamic theme bridge remains compatible with the six Doit Then themes.
- Theme, native-bridge, and date-parser Node tests passed.
- Unpacked development extension was tested with the development Doit Then app, and the user confirmed PASS.
- Development extension ID: `fdkkbdcnkigfhiabomhklbfapojbpdol`.
- Production extension ID: `nofdmceaajfglgpldmibhggabdjgbgnf`.
- Source manifest version remains 0.2.1. Chrome Web Store publication status for this source is unverified.
- No production extension publication or new helper package is included in this development commit.
- GitHub Actions remain manual-only.
- Next step: preserve validated development behavior; package and publish only through the separately authorized release workflow.


## CURRENT VERIFIED STATE — 2026-10-18 (READ FIRST)

- Repository: `TheCuriousProcrastinator/Add-to-Reminders`, default branch `main`, verified source HEAD before this documentation update: `c6d222d96ff52e61b5604949eaff2f7943171530`.
- Source `chrome-extension/manifest.json` version: **0.2.1** (Manifest V3). Its development `key` is retained for stable unpacked ID `fdkkbdcnkigfhiabomhklbfapojbpdol`; the submitted Web Store package omitted that key.
- User reported production Chrome Web Store extension **0.2**, then **submitted 0.2.1 for review** on 2026-10-18. **Approval and publication of 0.2.1 remain unverified.** Production extension ID: `nofdmceaajfglgpldmibhggabdjgbgnf`.
- The 0.2.1 submission includes dynamic light/dark HEX palettes from Doit Then, Paper Ember/Carbon Ember standalone fallback, and **the four icons from installed 0.2**. Regression tests and isolated local packaging checks passed.
- The submitted `Add-to-Reminders-0.2.1-Chrome-Web-Store.zip` was later reported **missing from its original Downloads path**. Its final SHA-256 and current local availability cannot be verified; GitHub contains the matching version/source and preserved icon files, but the submitted ZIP itself is not stored in this repository.
- Companion Doit Then **v1.0.26, build 40** was published and verified. Release source commit: `bbbf04dc4bd0a2cb59560619a58158b34d19e40e`.
- Separate macOS helper's latest verified GitHub Release is **v0.1.4**; the app's native host is preferred, with helper fallback when unavailable.
- Next external dependency: **Chrome Web Store review decision for 0.2.1**. When approved/published, verify production appearance/theme changes and reminder capture against Doit Then v1.0.26. No new extension change is authorized here.
- **Authority:** repository/source and actual Chrome Web Store dashboard first, this CURRENT section second. Older dated `current`, `next task`, `publication state`, `0.1.x` and packaging instructions below are **historical snapshots** where superseded. Preserve debugging detail but never downgrade the source version or submit the obsolete 0.1.19 ZIP.
- Only the handoff is changed by this documentation update; fetch updated `main` before editing the local checkout. No GitHub Actions run automatically.

## Chrome extension 0.2.1 submitted - 2026-10-18

- Chrome Web Store version 0.2.1 was submitted by the user.
- User confirmed local package preparation succeeded.
- Submitted package contained the dynamic theme implementation.
- Four icons from installed extension 0.2 were preserved.
- Installed 0.2 runtime was checked against the original baseline.
- Source icons were restored from the same installed 0.2 files
  used to prepare the submitted package.
- Local extension regression tests passed.
- The submitted ZIP was subsequently unavailable at its
  original Downloads path; its original SHA-256 is unverified.
- Chrome Web Store approval/publication remains unverified.
- Companion Doit Then 1.0.26 build 40 is published.
- GitHub Actions remain manual-only.

## Historical 0.1.19 package (not submitted; superseded by 0.2.1)

- Version: 0.1.19.
- User confirmed the dynamic theme functionality: PASS.
- Package: `~/Downloads/Add-to-Reminders-0.1.19-Chrome-Web-Store.zip`.
- ZIP SHA-256: `c481192c8fb91b329de84cf726a697c116300dc44cb6d6c2f43f7ff6bf3a447d`.
- Extension tests and ZIP integrity verified locally.
- Production and development extension host identities remain separate.
- Companion Doit Then v1.0.26 release commit: `bbbf04dc4bd0a2cb59560619a58158b34d19e40e`.
- Manifest key excluded from Chrome Web Store upload ZIP.
- This 0.1.19 package was **not submitted**; the user submitted the subsequent 0.2.1 package for review.
- GitHub Actions remain manual-only.


## 2026-10-18 validated dynamic Doit Then palettes

- Branch: `vibe/dynamic-chrome-palettes`.
- Starting source commit: `580ab369e63e8278e7ec5e22854f09e7f971593b`.
- Exact validated extension checkout: `/Users/alex/Desktop/tmp/DoitThen-dynamic-theme.4d80zR/Add-to-Reminders`.
- Companion app checkout: `/Users/alex/Desktop/tmp/DoitThen-dynamic-theme.4d80zR/DoitThen`.
- User explicitly confirmed local validation: PASS.
- Extension Node regression tests passed.
- Tested with the locally built Doit Then development app.

### Implementation

- `chrome-extension/extension-theme.js` accepts validated HEX
  palettes supplied by Doit Then.
- The existing native `themeInfo` schema remains version 1.
- Older Doit Then apps continue using the existing bundled
  named palettes.
- Without a connected app, the extension uses built-in
  Paper Ember in light appearance and Carbon Ember in dark.
- `popup.html` uses those fallback colors from initial rendering,
  replacing the generic blue appearance.
- Theme tests cover dynamic colors, legacy compatibility,
  unsafe CSS rejection, and standalone fallback.
- Reminder capture and other extension functionality are preserved.
- Development and production native-host identities remain separate.

### Historical pre-release status (superseded)

- Local development validation was PASS.
- Subsequently, Doit Then v1.0.26/build 40 was published, and Chrome extension 0.2.1 was submitted for review; its store approval/publication is unverified.
- GitHub Actions remain manual-only.

# VIBECODING_HANDOFF.md

## Publish/release command - standing authorization (2026-10-13)

- When the user says "publish", "release", "make update", or equivalent, treat that statement as standing authorization to complete the full validated local release and publication workflow. Do not ask for additional publication consent or confirmation.
- Never create Terminal scripts that ask the user to type "PASS", "YES", or another validation or confirmation keyword before publishing. Never introduce case-sensitive validation gates. A user statement such as "pass", "passed", "works", or equivalent is an explicit confirmation of the corresponding manual tests, regardless of capitalization.
- If the exact source change has already passed required local build/tests and the user confirmed required manual verification, proceed immediately with committing the exact tested source, handoff update, release build/signing/packaging, GitHub releases, Sparkle appcast publication, and live verification. Do not ask the user to repeat validation.
- Keep the non-negotiable local validation gate: do not publish unvalidated executable/build-affecting changes. If required validation genuinely has not happened, stop and explain that blocker, with the minimum required local test instructions; do not pretend validation passed.
- Stop only for real blockers such as missing local validation, failed build/test, unsafe working tree, missing signing credentials, or a failed release step. Do not create arbitrary pauses, keyword prompts, or extra approvals. Do not run GitHub Actions automatically.
- If local Mac access is unavailable, supply one copy-pasteable, **noninteractive** Terminal block to carry out already-authorized release actions in the exact validated Mac checkout. Use existing credentials/keychain without inventing confirmation prompts. If genuine credentials or macOS prompts are unavoidable, report them as blockers, not additional publication-approval requests.
- This rule takes precedence over older handoff wording that might suggest an additional user confirmation after validation. It does not override mandatory validation or source-of-truth checks.


## Shared Vibe Coding workflow rules (2026-10-08)

### Documentation-only handoff exception
- When the user explicitly requests a documentation-only update, ChatGPT may edit the existing root `VIBECODING_HANDOFF.md` directly through GitHub without requiring a Mac build or a local checkout step.
- First inspect the actual repository, target branch, and existing handoff. Change only the handoff, preserve historical project context, and verify the resulting GitHub file and commit. Do not use this exception for application code, tests, scripts, configuration, workflows, version/build changes, release assets, or other build-affecting files.
- Before the next local development change, fetch the remote branch and reconcile the updated handoff with the local checkout. Never overwrite or silently reset unrelated local changes.
- The normal rule remains: validate the exact executable/build-affecting changes in the real Mac checkout before committing or pushing those changes. Include a current handoff with every meaningful validated development commit.

### Temporary worktrees, releases, and logs
- Create temporary Git worktrees under `/Users/alex/Desktop/tmp/<project>-...` using a project-specific name.
- Put release working folders, temporary release artifacts, staging directories, and build/release logs under `/Users/alex/Desktop/tmp/<project>-release-...`.
- Do not create disposable worktrees inside `/Users/alex/Documents/Vibe Coding`.
- Do not place release artifacts or logs directly on the Desktop root.
- After a successful verified release, remove temporary worktrees and temporary release artifacts when safe. Do not remove active worktrees, uncommitted work, published assets, or permanent project files.
- Retain failure logs only when useful for debugging; remove unnecessary temporary logs.
- These instructions govern future operations and take precedence over historical temporary-path examples elsewhere in this handoff.

### Low-overhead development defaults
- Use ChatGPT plus GitHub inspection and Mac-local Terminal scripts by default; do not use Codex, ChatGPT Work, separately billed API agents, or GitHub Actions runners unless explicitly requested.
- Prefer existing project scripts. Give one local command block to apply, build, test, and launch an executable change, then a separate commit/push block only after required validation is confirmed.
- Documentation-only updates under the exception above do not require a rebuild.

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

## Current version and release state (verified 2026-10-18)

### Chrome extension source and distribution

- `main` manifest version: **0.2.1**, Manifest V3; `Add Website to Reminders` listing name, `Add to Reminders` action.
- Popup: `popup.html`; options: `options.html`; keyboard shortcut: `Alt+Shift+R` on macOS.
- Manifest permissions: `activeTab`, `storage`, `nativeMessaging`, `contextMenus`; no host permissions.
- Source manifest intentionally includes a development `key`; Web Store ZIP omits the copied `key` without changing other manifest permissions.
- The user reported Chrome Web Store version **0.2** and submitted **0.2.1** for review. Approval/publication of 0.2.1 is **not verified**. Check the Chrome Web Store dashboard, not GitHub, for review state.

### Separate native helper release

Latest verified GitHub Release: **v0.1.4**, `AddToRemindersHelper-0.1.4.pkg`, SHA-256 `43aa22cdb6ad26b103024c4a9eeb21a81db7c9ebcd92bdb2d4037d454eb8a524`; macOS 14+, Universal 2, ad-hoc signed. Supports Chrome and Chrome for Testing. The production app's native messaging host is preferred.

### Historical store context

Chrome Web Store 0.1.5 approval was recorded for 2026-08-31, and 0.1.17 publication was confirmed on 2026-10-03. Those are historical milestones, **not** the current version. The later installed production version was 0.2; the present submission is 0.2.1.

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
- `chrome-extension/native-bridge.js`
- `chrome-extension/extension-theme.js`
- `chrome-extension/test-date-parser.mjs`
- `chrome-extension/test-native-bridge.mjs`
- `chrome-extension/test-extension-theme.mjs`
- `chrome-extension/icons/`

The extension prefers Chrome Native Messaging host:

`com.thecuriousprocrastinator.doitthen.chrome`

and falls back to the standalone helper host:

`com.alex.addtoreminders`

Fallback occurs only when the preferred Doit Then host is genuinely
unavailable. A real permission, validation, or save error from Doit Then is
surfaced rather than silently falling back.

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
- `native-bridge.js`
- `extension-theme.js`
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
- Place the final review ZIP in a persistent, verified location (historically `dist/`; the 0.2.1 submission used Downloads). Verify its continued existence if a later step needs the exact bytes.

Do not use `/tmp` as the final Web Store artifact location.

Historical naming convention:

`AddToReminders-<version>-webstore.zip`

The submitted 0.2.1 package used `Add-to-Reminders-0.2.1-Chrome-Web-Store.zip` in Downloads. Naming alone does not verify package contents or continued availability.

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

Normal development and release validation is authoritative only when performed locally on the user's Mac.

The repository contains `.github/workflows/manual-validation.yml`.

That workflow is intentionally manual-only through `workflow_dispatch` and exists only for optional clean-environment verification when the user explicitly requests it.

GitHub Actions must not run automatically for feature-branch pushes, `main` pushes, pull requests, release/version tags, schedules, or other repository events.

Development and releases do not depend on GitHub Actions.

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

For the **current** cycle, the user submitted **0.2.1** on 2026-10-18 after reporting production version **0.2**. Approval/publication of 0.2.1 remains unverified; check the store dashboard before taking further publication action.

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

- Chrome Web Store 0.2.1 review outcome and publication status (check dashboard).
- Submitted 0.2.1 ZIP was missing from Downloads during subsequent handoff/commit work; no current copy or SHA-256 has been verified.
- Local working-tree cleanliness cannot be verified from GitHub; inspect before the next edit.
- Optional GitHub Actions clean-environment validation was not run and is not required.

## Exact next development task

1. Wait for the **Chrome Web Store 0.2.1 review decision**. It has been submitted; approval and publication have **not** been verified.
2. After publication, test production theme synchronization and reminder capture against **Doit Then v1.0.26/build 40**, preserving production/development native-host separation.
3. Before any *new* development, fetch `origin`, verify the exact branch and HEAD against the source of truth, and inspect `git status --short`. Do not reset, stash, merge, or overwrite unrelated local changes.
4. Begin new code work only when the user requests a specific change. Follow mandatory local build/tests and manual validation before commit or push.

## Suggested read-only local state check

```bash
cd "/Users/alex/Documents/Vibe Coding/AddToReminders" || exit 1
export GIT_PAGER=cat
git fetch origin
git status --short
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
python3 -c 'import json; print(json.load(open("chrome-extension/manifest.json"))["version"])'
git --no-pager log -5 --oneline --decorate
```

Do not switch branches or pull automatically when unrelated local changes are present.

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

## Local Mac + GitHub hosting policy - 2026-10-02

The user's Mac is the authoritative development and release environment.

GitHub is used for committed source/history, branches, tags, GitHub Releases and downloadable assets, and optional manually requested clean-environment verification.

GitHub Actions policy:

- no automatic runs on feature branches
- no automatic runs on `main`
- no automatic runs on pull requests
- no automatic runs on release/version tags
- no scheduled runs
- only explicit `workflow_dispatch` runs are allowed
- GitHub Actions is optional verification and is not part of the normal development or release loop

The native helper package and Chrome Web Store artifacts continue to be built and verified locally. `build-pkg.command` remains the helper packaging path.

GitHub does not back up signing identities, private keys, Keychain credentials, local secrets, ignored files, `dist/`, or uncommitted work.

This policy migration changes only `.github/workflows/manual-validation.yml` and this handoff. It does not change extension source, helper source, manifest version, package output, or runtime behavior.


---

<!-- chrome-extension-release-0.1.17 -->

## Chrome extension 0.1.17 release source - 2026-10-03

The exact locally validated Chrome extension from:

- branch: `vibe/doitthen-native-bridge`
- commit: `1937f211e483c05a5cc7a9f677c114bca3cc0aaf`

was promoted unchanged into `main`.

Version:

`0.1.17`

Validated production behavior:

- prefers `com.thecuriousprocrastinator.doitthen.chrome`
- falls back to `com.alex.addtoreminders` only when Doit Then is unavailable
- does not mask real Doit Then permission/save/request errors
- popup follows Doit Then theme
- Settings follows Doit Then theme
- falls back to System appearance when Doit Then is unavailable
- real six-scenario host fallback matrix passed
- reminder creation passed
- list/date/priority parsing regressions passed

Web Store artifact:

`dist/AddToReminders-0.1.17-webstore.zip`

The source manifest retains its development `key` for the stable unpacked
extension ID. The Web Store ZIP removes only that copied `key`.

Production Chrome Web Store ID:

`nofdmceaajfglgpldmibhggabdjgbgnf`

Chrome Web Store version 0.1.17 was uploaded to the existing production
listing and the user confirmed the publication step passed.

No additional Doit Then / Add to Reminders integration work is currently
required.


---

<!-- chrome-web-store-0.1.17-published -->

## Chrome Web Store 0.1.17 publication complete - 2026-10-03

The user confirmed the Chrome Web Store publication step passed for extension
version **0.1.17**.

Production extension ID:

`nofdmceaajfglgpldmibhggabdjgbgnf`

Final integration state:

- Doit Then 1.0.4 build 18 published
- Sparkle release/update feed verified
- automatic Doit Then Native Messaging registration released
- Add to Reminders 0.1.17 source on `main`
- Chrome Web Store 0.1.17 publication completed
- standalone Add to Reminders Helper remains supported as fallback

No additional integration work is currently required.

---

## Doit Then extension check-in - validated 2026-10-04

Local validation: PASS.

Development branch:

`vibe/doitthen-extension-checkin`

Validated base:

`95621c175ef79a9c14dc89839bdac6db00e6a71e`

Development extension version:

`0.1.18`

### Purpose

The extension reports its presence to Doit Then through the existing Native Messaging connection.

### Architecture

The extension sends a lightweight `ping` containing its extension version.

Doit Then records successful Native Messaging contact as the availability source of truth.

Do not replace this with Chrome profile or extension-folder inspection.

### Development host isolation

Unpacked development extension ID:

`fdkkbdcnkigfhiabomhklbfapojbpdol`

Development host:

`com.thecuriousprocrastinator.doitthen.chrome.dev`

Production host:

`com.thecuriousprocrastinator.doitthen.chrome`

This prevents development Doit Then builds from overwriting production Native Messaging registration.

### Validated behavior

Manual validation passed for:

- unpacked 0.1.18 extension connects to development Doit Then
- Doit Then recognizes extension check-in
- reminder creation still works
- Doit Then theme sync still works
- production and development Native Messaging hosts remain independent

Automated syntax, Native Messaging bridge, and theme tests passed before manual validation.

No GitHub Actions run is required for this development push.


## Automatic handoff synchronization (2026-10-19)

- The tracked `.githooks/pre-commit` runs `Tools/vibe_handoff.py sync-staged` locally. It reads version/build from the Git index, reads the GitHub published release, refreshes only the bounded generated current-state section and stages the handoff in the same commit. It does **not** modify application code or establish build/manual-test validation.
- On a fresh Mac checkout, run `sh .githooks/install.sh` once. It refuses to replace an existing pre-commit hook. Do not bypass hooks with `--no-verify`. Changes to feature behavior, debugging decisions, known issues, manual validation, and next work still require a human-maintained narrative entry after the exact local test passes.
- Do not commit or push any executable change before successful validation in the real Mac checkout. The tool makes documentation updates only; GitHub Actions remain manual only.
- Sparkle applications' release scripts refresh generated release facts in source and update-feed handoffs once their respective release milestones are reached. Verify the live release/feed before claiming publication succeeded. Projects without a scripted release must refresh and commit the handoff after externally verifying publication.
- If GitHub release status cannot be verified, or the handoff contains unstaged edits, the hook blocks rather than guessing or overwriting your changes.
