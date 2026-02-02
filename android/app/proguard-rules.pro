# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Supabase & Helpers
-keep class io.supabase.** { *; }

# Safe Device
-keep class com.example.safe_device.** { *; }

# General Flutter
-dontwarn io.flutter.embedding.**
-ignorewarnings
