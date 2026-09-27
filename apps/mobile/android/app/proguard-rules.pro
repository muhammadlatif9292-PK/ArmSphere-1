# ArmSphere Production Proguard & R8 Configuration

# Flutter Framework & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AndroidX Biometric & Security (local_auth)
-keep class androidx.biometric.** { *; }
-keep class androidx.security.crypto.** { *; }

# Stripe Android SDK
-dontwarn com.stripe.android.**
-keep class com.stripe.android.** { *; }

# Core Desugaring & JSON Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google Tink & Secure Storage
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Play Core & Flutter Deferred Components (SplitCompat)
-dontwarn com.google.android.play.core.**

