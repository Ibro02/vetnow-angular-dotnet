# R8 rules for the release build.
#
# Deliberately short. The Flutter engine and each plugin ship their own
# consumer ProGuard rules, which Gradle merges in automatically — adding
# a blanket `-keep class io.flutter.** { *; }` on top of that keeps
# thousands of classes R8 had correctly decided were unreachable, which
# is most of the reason to run R8 at all.

# --- Play Core / deferred components ---
# The engine carries a PlayStoreDeferredComponentManager that talks to
# the Play Core split-install API. This app does not use deferred
# components, so that library is not on the classpath and R8 reports the
# references as missing classes. They are unreachable, not broken.
-dontwarn com.google.android.play.core.**

# --- flutter_secure_storage ---
# Goes through AndroidX security-crypto, which resolves its master key
# provider reflectively; R8 cannot see those references.
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn javax.annotation.**

# --- Crash readability ---
# Without this every stack trace from a release build is method names
# with no line numbers, which makes a report from the field close to
# useless. The names are still obfuscated; the mapping file under
# build/app/outputs/mapping/release/ is what turns them back.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
