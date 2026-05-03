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

# Keep model classes (used by reflection for JSON serialization)
-keep class com.imma96.virtual_status_worlds.** { *; }
