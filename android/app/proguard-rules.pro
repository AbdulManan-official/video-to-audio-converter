# =========================
# Flutter Wrapper classes
# =========================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }

# =========================
# Kotlin classes
# =========================
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# =========================
# Gson (if using JSON serialization)
# =========================
-keep class com.google.gson.** { *; }

# =========================
# Play Core classes
# =========================
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# =========================
# FFmpeg plugin classes
# =========================
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# =========================
# Keep any annotations
# =========================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# =========================
# Flutter plugin classes
# =========================
-keep class io.flutter.plugins.** { *; }

# =========================
# Google Mobile Ads - CRITICAL
# =========================
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**

# =========================
# Flutter Downloader - CRITICAL
# =========================
-keep class vn.hunghd.flutterdownloader.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-dontwarn vn.hunghd.flutterdownloader.**
-dontwarn androidx.work.**

# =========================
# Permission Handler - CRITICAL
# =========================
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# =========================
# Device Info Plus
# =========================
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# =========================
# Just Audio
# =========================
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.just_audio.**

# =========================
# Shared Preferences
# =========================
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# =========================
# GetX (State Management)
# =========================
-keep class com.get.** { *; }
-keepclassmembers class * extends com.get.** { *; }

# =========================
# Google Fonts
# =========================
-keep class io.flutter.plugins.googlemobileadsplatform.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }