# Keep ML Kit classes from being minified/obfuscated by R8 in release builds
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-keep class com.google.android.odml.** { *; }
