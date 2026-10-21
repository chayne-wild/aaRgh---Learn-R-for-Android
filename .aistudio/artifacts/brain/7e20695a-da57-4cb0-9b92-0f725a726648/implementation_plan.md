# aaRgh — Offline Boot Fix, Dependency Hardening & Input Lock Plan

Resolves the stuck *"Booting offline Base R..."* screen by bundling the missing `webr/R.wasm` binary into the APK, hardening both `swirl_offline_engine.R` and `webr/R.js` so intentionally omitted packages or VFS files never block startup or lesson execution, and locking all input and command buttons until the R engine finishes booting.

## User Review & Critical Decisions

> [!IMPORTANT]
> All decisions confirmed from your answers and technical notes are included below:

- **Confirmed Decision 1 — Bundle `webr/R.wasm` Offline**: Download the matching `R.wasm` binary for the bundled `webR` (`0.5.10-dev` / Base R `4.6.0`) and place it inside `app/src/main/assets/aargh_bundle/webr/R.wasm` so the app boots 100% offline on both the emulator and physical phones.
- **Confirmed Decision 2 — Fail-Safe Dependency & VFS Shimming**:
  - Patch `swirl_offline_engine.R` to comment out explicit `library()` / `require()` calls and intercept `library()`, `require()`, `requireNamespace()`, `loadNamespace()`, `find.package("swirl")`, `system.file(..., package = "swirl")`, `digest()`, and the `::` / `:::` namespace operators (which are used by several `initLesson.R` and `customTests.R` scripts via `swirl:::swirl_courses_dir` and `httr::POST`).
  - Harden `webr/R.js` (`createLazyFilesystem`) so any intentionally omitted optional VFS files never throw a fatal error during startup or runtime.
- **Confirmed Decision 3 — Lock All Input & Command Controls During Boot**: Disable `#r-input`, `#send-btn`, the `[R]`/`[Math]` operator keys, and the top-bar R command buttons (`swirl()`, `play()`, `nxt()`, `skip()`, `main()`, `bye()`) while the engine is booting, and unlock them automatically the moment Base R emits its first ready prompt.

---

## 1. Overview & Core Concept

- **What It Does**: Guarantees that **aaRgh** boots reliably into the interactive `swirl()` console with zero internet connection, blocks premature user input while WebAssembly initializes, and runs every `R Programming` lesson without crashing on missing external packages or omitted VFS files.
- **Target Audience / Persona**: R learners and users testing or installing the standalone Android APK on their phone or emulator.
- **Key Value**:
  - Eliminates the infinite *"Booting offline Base R..."* hang caused by the missing `R.wasm` file.
  - Prevents accidental input queuing while the engine is still loading.
  - Protects every lesson (`Looking_at_Data`, `lapply_and_sapply`, `vapply_and_tapply`, `Functions`, `Base_Graphics`, etc.) from failing on `library(stringr)`, `swirl:::swirl_courses_dir`, or `httr::POST`.

---

## 2. User Experience & Visual Design

- **Key User Flows**:
  1. **Locked Boot State**: While Base R initializes and unpacks `aargh_payload.tar`, the status dot is amber (`#f59e0b`), the input box displays `"Wait for R engine..."`, and the text input, `Send` button, operator keys, and top R command buttons (`swirl()`, `play()`, `nxt()`, `skip()`, `main()`, `bye()`) are visually dimmed (`opacity: 0.5`) and `disabled`. (`Theme` and `Keys` remain interactive so the user can still toggle Light/Dark mode).
  2. **Automatic Unlock & `swirl()` Launch**: As soon as `R.wasm` finishes loading `swirl_offline_engine.R` and emits its first prompt, the status dot turns green (`#16a34a`), all controls unlock immediately, `#r-input` updates its placeholder to `"Type or swipe R command..."`, and `swirl()` launches automatically.
  3. **Fault-Tolerant Lesson Execution**: When the user selects or skips through any lesson in `R Programming`, shimmed calls (`library(stringr)`, `library(swirl)`, `library(yaml)`, `swirl:::swirl_courses_dir`, `httr::POST`, `digest()`) resolve seamlessly in pure Base R without attempting to load external C packages or network libraries.
- **Visual Identity & Theme**:
  - Retains the clean, high-contrast Light Mode default (`#f8fafc` background, `#ffffff` panels, `#0f172a` text) and 1-tap Dark Mode toggle (`#0f1419` background, `#182026` panels), with clear disabled-state styling (`opacity: 0.5; pointer-events: none`) during boot.

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1 — Complete Offline Package & Namespace Operator Interception (`library`, `require`, `::`, `:::`, `find.package`)**
  - *Chosen Approach*: In addition to shimming `library()` and `require()` and commenting out explicit calls in `swirl_offline_engine.R`, also intercept `::` and `:::` for `.shimmed_pkgs` (`"swirl"`, `"stringr"`, `"yaml"`, `"testthat"`, `"httr"`, `"RCurl"`, `"digest"`, `"crayon"`, `"rlang"`, `"cli"`, `"glue"`, `"lifecycle"`, `"magrittr"`, `"stringi"`) and rewrite `swirl:::swirl_courses_dir` in course `initLesson.R` files before packing `aargh_payload.tar`.
  - *Why*: In R, `swirl:::swirl_courses_dir` and `httr::POST` bypass `library()` and invoke `loadNamespace()` directly. Shimming both `library()`/`require()` and `::`/`:::` ensures no lesson script can ever fail on an omitted package.
- **Decision 2 — Fault-Tolerant VFS Lazy Loading in `webr/R.js`**
  - *Chosen Approach*: Guard lazy file/image mounting in `R.js` with `try / catch` and graceful fallback so intentionally omitted VFS documentation or auxiliary archives never halt the R runtime.
  - *Why*: Keeps the APK self-contained and resilient even when non-essential R files are omitted by design.

---

## 4. Technical Architecture & Data Strategy *(Technical Reference)*

### Architecture & Component Diagram

```
┌───────────────────────────────────────────────────────────────────────────┐
│                     APK Boot & Asset Layer (Offline)                      │
│  • WebViewAssetLoader serves assets/aargh_bundle/ with COOP + COEP        │
│  • Bundled webr/R.wasm + R.js (fault-tolerant VFS lazy loader)            │
│  • Bundled aargh_payload.tar (patched swirl_offline_engine.R + courses)   │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                   UI Boot Lock StateMachine (index.html)                  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ BOOTING (isEngineReady = false):                                    │  │
│  │  • Status dot: Amber (#f59e0b)                                      │  │
│  │  • Locked (disabled): #r-input, #send-btn, .op-key, .cmd-btn        │  │
│  │  • Active: Theme toggle (🌙/☀️), Keys toggle                        │  │
│  ├─────────────────────────────────────────────────────────────────────┤  │
│  │ READY (First R prompt received -> isEngineReady = true):            │  │
│  │  • Status dot: Green (#16a34a)                                      │  │
│  │  • Unlocks: #r-input, #send-btn, .op-key, .cmd-btn                  │  │
│  │  • Auto-dispatches: webRConsole.stdin('swirl()\n')                  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                Pure Base R Offline Guard (swirl_offline_engine.R)         │
│  • Intercepts: library(), require(), requireNamespace(), loadNamespace()  │
│  • Intercepts: :: and ::: operators (e.g. swirl:::swirl_courses_dir)      │
│  • Shims: find.package("swirl"), system.file(..., package="swirl"),       │
│           yaml.load_file() -> readRDS(), stringr::*, testthat::*, digest()│
└───────────────────────────────────────────────────────────────────────────┘
```

### Interactive Component & State Mapping

- **`setEngineReady(ready)` Lock Handler**: Toggles `disabled` and `.boot-locked` across `#r-input`, `#send-btn`, `#mode-btn`, all `.op-key` buttons, and all `.cmd-btn` top bar buttons (`swirl()`, `play()`, `nxt()`, `skip()`, `main()`, `bye()`), and guards `window.sendCommand()` and `window.submitInput()` so nothing can be sent while `isEngineReady === false`.
- **Offline Guard & Course Sanitizer**: Strips explicit `library()`/`require()` calls and replaces `swirl:::swirl_courses_dir` / `httr::POST` references across `swirl_offline_engine.R` and `courses/` prior to creating `aargh_payload.tar`, backed by runtime interceptors in `.GlobalEnv`.
