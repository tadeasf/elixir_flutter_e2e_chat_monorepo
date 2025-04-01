# Keep Google Error Prone annotations
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Keep JSR305 annotations
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }

# Keep Tink crypto library classes
-dontwarn com.google.crypto.tink.**
-keep class com.google.crypto.tink.** { *; }
-keepclassmembers class com.google.crypto.tink.** { *; }

# Keep Play Core classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep Kotlin Metadata
-keep class kotlin.Metadata { *; }

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# General
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception 