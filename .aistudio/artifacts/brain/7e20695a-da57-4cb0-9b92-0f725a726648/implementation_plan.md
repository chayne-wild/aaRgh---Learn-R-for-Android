# aaRgh — Classic Minimalist Offline Android R & swirl Console

A 100% offline, zero-account native Android application in Kotlin and Jetpack Compose that boots straight into a classic, minimalist Base R (`webR`) and `swirl` console—allowing users to run R calculations, freely jump or skip between any `swirl()` lessons, and view plots in both upright (portrait) and sideways (landscape) orientations.

## User Review & Critical Decisions

> [!IMPORTANT]
> Updated per your feedback to ensure a strictly minimalist, device-only architecture:

- **Zero Logins / Strictly Device-Local State**: There are **no login screens, no user accounts, and no cloud services**. The only name prompt is `swirl`'s classic console question (`"What shall I call you?"`). All state lives strictly inside the Android app's private on-device storage (`WebView` local storage / `IDBFS` + `SharedPreferences`)—if the user uninstalls the app or switches phones, their data is simply gone.
- **Classic Minimalist R + `swirl()` Experience**: Boots directly into the R console and starts `swirl()`. Users can freely skip questions or lessons (`skip()`, `main()`), pause (`play()`), resume (`nxt()`), or exit `swirl()` (`bye()`) to use pure Base R for math and data exploration.
- **Upright & Sideways (Portrait & Landscape) + Native Keyboard**: Rotating the phone never reloads the R session. The native phone keyboard (Gboard swipe/glide typing, personal dictionary, autocorrect off) works seamlessly alongside the non-wrapping R operator bar and 1-tap `swirl` menu pills.

---

## 1. Overview & Core Concept

- **What It Does**: Embeds a complete offline Base R engine (`webR`) and pre-packaged `swirl` courses (`aargh_payload.tar`) inside a clean, distraction-free Android terminal interface.
- **Target Audience / Persona**: Anyone wanting a straightforward, offline R console and interactive `swirl` learning environment on their Android phone with zero sign-up friction.
- **Key Value**:
  - **Instant, Classic R Feel**: Opens directly to the R console—no onboarding carousels, accounts, or menus outside R itself.
  - **Effortless `swirl()` Navigation**: Users can tap numbered course/lesson choices (`1: R Programming`, etc.) directly in the transcript or use the top bar (`swirl()`, `play()`, `nxt()`, `skip()`, `main()`, `bye()`) to jump to any lesson or drop into free R calculation mode.
  - **Mobile-First Ergonomics**: Works upright (portrait) and sideways (landscape) without losing progress, respects native phone keyboards, and provides 1-tap R symbols (`<`, `-`, `|`, `>`, `$`, etc.) that never steal keyboard focus.

---

## 2. User Experience & Visual Design

- **Key User Flows**:
  1. **Direct Console Launch**: App opens immediately into the R console in clean Light Mode (or Dark Mode if previously toggled). `aargh_payload.tar` is unpacked into the virtual filesystem via Base R `utils::untar()`, `swirl_offline_engine.R` is sourced, and `swirl()` launches automatically.
  2. **Navigating & Skipping `swirl()` Freely**:
     - `swirl` asks `"What shall I call you?"` directly in the console transcript.
     - Numbered menu options (`1: R Programming`, `1: Basic Building Blocks`, `2: Workspace and Files`, etc.) appear as clickable pill buttons in the transcript so users can pick any lesson in one tap.
     - At any point, tapping `skip()` skips the current question, `main()` returns to the lesson selector so the user can pick a different lesson, `play()` lets them experiment freely in R, `nxt()` resumes, and `bye()` exits to the standard `>` R prompt for basic math and statistics.
  3. **Upright (Portrait) & Sideways (Landscape) Use**:
     - Rotating the device sideways compacts the bar heights automatically so the transcript stays readable above the keyboard, and the `Keys` button lets the user collapse or expand the operator row with one tap.
  4. **Pop-Out Plot Window**: Running any plotting command in R or `swirl` (`plot()`, `hist()`, `boxplot()`, etc.) opens a clean modal window with pinch-to-zoom and pan support.
- **Visual Identity & Theme**:
  - *Aesthetic Direction*: Classic, minimalist, utilitarian R console.
  - *Color Palette & Mood*:
    - **Light Mode (Default)**: `--bg: #f8fafc`, `--panel: #ffffff`, `--bar-bg: #f1f5f9`, `--border: #cbd5e1`, `--text: #0f172a`, `--accent: #0284c7`, `--cmd: #15803d`, `--prompt-bg: #e0f2fe`, `--prompt-fg: #0369a1`, `--err: #dc2626`.
    - **Dark Mode (1-Tap Toggle)**: `--bg: #0f1419`, `--panel: #182026`, `--bar-bg: #12181f`, `--border: #2a3540`, `--text: #e6edf3`, `--accent: #38bdf8`, `--cmd: #4ade80`, `--prompt-bg: #1e293b`, `--prompt-fg: #7dd3fc`, `--err: #f87171`.

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1 — Simple On-Device Persistence Only (No Accounts, No Cloud)**
  - *Chosen Approach*: Keep all user state strictly inside the Android device's sandbox (`IDBFS` mounted at `/persist` inside the WebView's on-device IndexedDB + `localStorage` for Light/Dark theme). If `IDBFS` is unavailable or cleared, the app gracefully runs in-memory without ever blocking or prompting the user.
  - *Why*: Matches the exact mental model of a classic local tool—zero sign-in walls, 100% offline, and cleanly erased if the app is uninstalled.
- **Decision 2 — Exact Script `index.html` + Base R `utils::untar` + Patched `swirl_offline_engine.R`**
  - *Chosen Approach*: Use the exact `swirl_offline_engine.R` offline guard (intercepting `library`/`require` and shimming `digest`), pack `swirl_offline_engine.R`, `swirl_inst`, and `courses` into `aargh_payload.tar`, unpack via Base R `utils::untar()`, and serve with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` via `WebViewAssetLoader`.
  - *Why*: Proven to work reliably with `SharedArrayBuffer` so R's synchronous `readline()` and `swirl()` menus work out of the box.

---

## 4. Technical Architecture & Data Strategy *(Technical Reference)*

### Architecture & Component Diagram

```
┌───────────────────────────────────────────────────────────────────────────┐
│                   MainActivity (Kotlin + Jetpack Compose)                 │
│  • configChanges="orientation|screenSize|screenLayout|keyboardHidden|..." │
│  • windowSoftInputMode="adjustResize" (Portrait & Landscape keyboard)     │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                AarghWebViewHolder (Persistent On-Device Host)             │
│  • Keeps single WebView alive across upright <-> sideways rotation        │
│  • WebViewAssetLoader -> https://appassets.androidplatform.net/assets/... │
│  • Attaches COOP: same-origin & COEP: require-corp for SharedArrayBuffer  │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│             Minimalist Console UI (assets/aargh_bundle/index.html)        │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Top Bar: ● aaRgh | swirl() play() nxt() skip() main() bye()         │  │
│  │                  | Plot Keys Theme (🌙 Dark / ☀️ Light)             │  │
│  ├─────────────────────────────────────────────────────────────────────┤  │
│  │ Console Transcript: R output, .line-prompt questions,               │  │
│  │                     1-tap .menu-choice-btn course/lesson pills      │  │
│  ├─────────────────────────────────────────────────────────────────────┤  │
│  │ Continue Bar: "... Tap here or press Enter to Continue ..."         │  │
│  ├─────────────────────────────────────────────────────────────────────┤  │
│  │ Bottom Dock:                                                        │  │
│  │  • #var-chips (1-tap backticked R variables/functions)              │  │
│  │  • #r-input (Native phone keyboard / Gboard swipe safe) + Send      │  │
│  │  • #op-bar ([R] / [Math] single-char operator keys, collapsible)    │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────┬─────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│              Offline Base R (webR) + Patched swirl Engine                 │
│  • Unpacks aargh_payload.tar via Base R utils::untar()                    │
│  • Stores swirl progress locally in on-device /persist (IDBFS)            │
└───────────────────────────────────────────────────────────────────────────┘
```

### Interactive Component & State Mapping

- **Course & Lesson Skipping (`skip()`, `main()`, `play()`, `nxt()`, `bye()`)**: Top bar buttons send commands directly to `webRConsole.stdin()`, allowing the user to skip any question, jump back to the main lesson menu, pause `swirl` to run ad-hoc R math, or exit `swirl` completely.
- **Native Keyboard & Operator Bar Focus**: `#r-input` checks `e.isComposing` so Gboard glide typing is never interrupted, while all operator keys and variable chips use `onpointerdown` + `event.preventDefault()` so tapping R symbols never closes the keyboard.
- **Sideways (Landscape) & Upright (Portrait) Continuity**: `MainActivity` handles configuration changes without recreating the `WebView`, and CSS media queries compact bar heights in landscape while `Keys` toggles the operator row.
