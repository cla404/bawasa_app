# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Supabase classes
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }
-keep class org.bouncycastle.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep your app classes
-keep class com.example.bawasa_system.** { *; }

# Keep data classes used by Supabase
-keep class * implements java.io.Serializable { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep JavaScript interface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Suppress warnings for Supabase
-dontwarn com.supabase.**
-dontwarn io.supabase.**
-dontwarn org.bouncycastle.**

# Print configuration for debugging
-printconfiguration proguard-rules-pro.txt

