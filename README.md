# aaRgh — 100% Offline Native Android R Console & swirl Learning App

**aaRgh** is a native Android application built with **Kotlin** and **Jetpack Compose** that embeds a 100% offline **Base R** (`webR` WebAssembly) statistical environment and interactive **swirl** courses (`R Programming`).

## Architecture & Key Features

1. **Offline `webR` + `SharedArrayBuffer` Asset Loader (`AarghWebViewHolder.kt`)**:
   - Uses `androidx.webkit.WebViewAssetLoader` mapped to `https://appassets.androidplatform.net/assets/`.
   - Injects `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` on every `WebResourceResponse` in `shouldInterceptRequest`, enabling `window.crossOriginIsolated == true` and `SharedArrayBuffer` (`Atomics.wait`) with zero network access so R's `readline()` and `swirl()` menus pause synchronously for user input.
   - Mounts `/persist` via Emscripten `IDBFS` and configures `swirl_data_dir = "/persist/user_data"` and `.RData` autosaving so `swirl` progress and R workspace variables persist across app restarts.
   - Extracts the pre-built `aargh_payload.tar` bundle (with fallback to `vfs_manifest.json`) into `/persist/aargh_bundle`.

2. **Light Mode Default + Dark Mode Toggle (`Theme.kt`, `AarghViewModel.kt`, `index.html`)**:
   - Defaults to a high-contrast Light Mode palette (`#F8FAFC` background, `#FFFFFF` panels, `#0F172A` text) with a 1-tap `Theme` toggle in the top bar persisted across `SharedPreferences` and `localStorage`.

3. **Persistent, Non-Overlapping Responsive Layout (`AndroidManifest.xml`, `MainActivity.kt`, `AarghScreen.kt`)**:
   - Declares `android:configChanges="orientation|screenSize|screenLayout|keyboardHidden|uiMode"` and `android:windowSoftInputMode="adjustResize"` on `MainActivity` and retains the `WebView` instance inside `AarghWebViewHolder` so rotating between portrait and landscape never reloads the R session.
   - Single-row horizontally scrollable Top App Bar (`swirl()`, `play()`, `nxt()`, `skip()`, `main()`, `bye()`, `Plot`, `Keys`, `Theme`), Dynamic Variable Chips row, and Primitive Operator Bar (`[R]` / `[Math]`) with automatic landscape compaction and a 1-tap `[Keys]` collapse/expand toggle.

4. **Native Phone Keyboard, Gboard & Glide Typing Support**:
   - Configures `autocapitalize="none"`, `autocorrect="off"`, `spellcheck="false"`, `inputmode="text"`, and `enterkeyhint="send"`.
   - Protects active IME swipe/composition gestures (`e.isComposing`), normalizing curly smart quotes only after composition completes.
   - Uses `pointerdown` + `preventDefault()` on all operator keys and variable chips so the input field never loses focus and the on-screen keyboard never flickers.

5. **Pop-Out Plot Window with Pinch-to-Zoom**:
   - Automatically displays `webr::canvas` plots in a dismissible modal window with multi-touch pinch-to-zoom, pan gestures, and zoom controls.
