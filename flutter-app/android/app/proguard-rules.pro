# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Riverpod
-keep class riverpod.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences { *; }

# General Android
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*

# Gson / JSON (if used by plugins)
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Kotlin coroutines / serialization used by plugins
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }

# LiveKit / WebRTC (reflection-heavy)
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# R8: suppress missing optional dependencies
-dontwarn com.google.android.play.core.**
-dontwarn com.tekartik.sqflite.**
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
