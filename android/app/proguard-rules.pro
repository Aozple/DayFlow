# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }
-keep class com.google.android.gms.** { *; }

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keep class io.flutter.plugins.** { *; }

# Timezone
-keep class com.google.android.gms.internal.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }