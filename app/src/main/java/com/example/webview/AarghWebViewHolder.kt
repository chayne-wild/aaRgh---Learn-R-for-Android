package com.example.webview

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.webkit.WebViewAssetLoader
import com.example.viewmodel.AarghViewModel

/**
 * Persistent holder for the offline webR + swirl WebView instance so device rotation
 * (portrait <-> landscape) never reloads the R engine or loses user session progress.
 */
object AarghWebViewHolder {

    const val ASSET_HOST = "appassets.androidplatform.net"
    const val START_URL = "https://appassets.androidplatform.net/assets/aargh_bundle/index.html"

    @Volatile
    private var webViewInstance: WebView? = null

    private class AndroidBridge(
        private val viewModel: AarghViewModel
    ) {
        @JavascriptInterface
        fun getThemeMode(): String = viewModel.getThemeModeString()

        @JavascriptInterface
        fun setThemeMode(mode: String) {
            viewModel.setThemeModeFromString(mode)
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun getOrCreateWebView(
        context: Context,
        viewModel: AarghViewModel
    ): WebView {
        val existing = webViewInstance
        if (existing != null) {
            (existing.parent as? ViewGroup)?.removeView(existing)
            return existing
        }

        val appContext = context.applicationContext
        val assetLoader = WebViewAssetLoader.Builder()
            .setDomain(ASSET_HOST)
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(appContext))
            .build()

        return WebView(appContext).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#F8FAFC"))
            isFocusable = true
            isFocusableInTouchMode = true

            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = false
                allowContentAccess = false
                mediaPlaybackRequiresUserGesture = false
                cacheMode = WebSettings.LOAD_DEFAULT
                setSupportZoom(false)
                builtInZoomControls = false
                displayZoomControls = false
            }

            addJavascriptInterface(AndroidBridge(viewModel), "AndroidBridge")

            webChromeClient = WebChromeClient()

            webViewClient = object : WebViewClient() {
                override fun shouldInterceptRequest(
                    view: WebView,
                    request: WebResourceRequest
                ): WebResourceResponse? {
                    val rawUrl = request.url
                    val normalizedUrl = if (rawUrl.path?.contains("/webr/webr/") == true) {
                        rawUrl.buildUpon()
                            .path(rawUrl.path!!.replace("/webr/webr/", "/webr/"))
                            .build()
                    } else {
                        rawUrl
                    }
                    val response = assetLoader.shouldInterceptRequest(normalizedUrl) ?: return null
                    val path = normalizedUrl.path.orEmpty().lowercase()

                    // Ensure accurate MIME types for ES modules, WebAssembly, and R bundle archives
                    when {
                        path.endsWith(".mjs") || path.endsWith(".js") -> {
                            response.mimeType = "text/javascript"
                        }
                        path.endsWith(".wasm") -> {
                            response.mimeType = "application/wasm"
                        }
                        path.endsWith(".css") -> {
                            response.mimeType = "text/css"
                        }
                        path.endsWith(".html") -> {
                            response.mimeType = "text/html"
                        }
                        path.endsWith(".json") || path.endsWith(".metadata") -> {
                            response.mimeType = "application/json"
                        }
                        path.endsWith(".tar") || path.endsWith(".rds") || path.endsWith(".gz") || path.endsWith(".so") -> {
                            response.mimeType = "application/octet-stream"
                        }
                    }

                    // Attach COOP/COEP headers to enable window.crossOriginIsolated & SharedArrayBuffer (Atomics.wait)
                    val updatedHeaders = HashMap<String, String>()
                    response.responseHeaders?.let { updatedHeaders.putAll(it) }
                    updatedHeaders["Cross-Origin-Opener-Policy"] = "same-origin"
                    updatedHeaders["Cross-Origin-Embedder-Policy"] = "require-corp"
                    updatedHeaders["Cross-Origin-Resource-Policy"] = "same-origin"
                    updatedHeaders["Access-Control-Allow-Origin"] = "https://$ASSET_HOST"
                    response.responseHeaders = updatedHeaders

                    return response
                }
            }

            loadUrl(START_URL)
            webViewInstance = this
        }
    }

    fun evaluateRCommand(command: String) {
        val escaped = command
            .replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\n", "\\n")
        webViewInstance?.post {
            webViewInstance?.evaluateJavascript("window.sendCommand && window.sendCommand('$escaped');", null)
        }
    }

    fun insertSymbolAtCursor(symbol: String) {
        val escaped = symbol
            .replace("\\", "\\\\")
            .replace("'", "\\'")
        webViewInstance?.post {
            webViewInstance?.evaluateJavascript("window.insertAtCursor && window.insertAtCursor('$escaped');", null)
        }
    }

    fun toggleThemeInWebView() {
        webViewInstance?.post {
            webViewInstance?.evaluateJavascript("window.toggleTheme && window.toggleTheme();", null)
        }
    }

    fun toggleKeysInWebView() {
        webViewInstance?.post {
            webViewInstance?.evaluateJavascript("window.toggleKeysBar && window.toggleKeysBar();", null)
        }
    }

    fun openPlotModalInWebView() {
        webViewInstance?.post {
            webViewInstance?.evaluateJavascript("window.togglePlotModal && window.togglePlotModal(true);", null)
        }
    }
}
