# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Camera
-keep class androidx.camera.** { *; }

# Crypto
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# AndroidX Navigation
-keep class androidx.navigation.** { *; }
-keep class androidx.navigationevent.** { *; }
-dontwarn androidx.navigation.**
-dontwarn androidx.navigationevent.**

# Keep all annotations
-keepattributes *Annotation*
-dontwarn javax.annotation.**
