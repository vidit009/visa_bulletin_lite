# Flutter Proguard Rules for Release Builds
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WorkManager background execution
-keep class androidx.work.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }

# Local Notifications Plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Java 8+ Desugaring
-keepattributes *Annotation*
-dontwarn java.lang.invoke.**

# Play Core / Flutter Deferred Components
-dontwarn com.google.android.play.core.**
