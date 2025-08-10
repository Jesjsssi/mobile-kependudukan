# Keep missing annotation classes
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Preserve the Play Core library
-keep class com.google.android.play.core.** { *; }

# Keep Google API Client
-keep class com.google.api.** { *; }
-keep class com.google.api.client.** { *; }
-keep class com.google.api.client.http.** { *; }
-keep class com.google.api.client.json.** { *; }

# Keep HTTP Transport
-keep class com.google.api.client.http.** { *; }
-keep class com.google.api.client.http.javanet.** { *; }

# Keep Joda Time
-keep class org.joda.time.** { *; }

# Keep Tink crypto library
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.crypto.tink.util.** { *; }

# General annotations
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }
-keep class com.google.errorprone.annotations.** { *; }
-keep class org.checkerframework.** { *; }

# Tasks related stuff
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }

# Keep all referenced basic Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Ignore warnings about missing dependencies in release build
-dontwarn com.google.api.**
-dontwarn com.google.api.client.**
-dontwarn com.google.android.play.core.**
-dontwarn org.joda.time.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
