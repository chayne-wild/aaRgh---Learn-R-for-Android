# Keep JavascriptInterface methods on AndroidBridge for WebView communication
-keepattributes *Annotation*,JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
