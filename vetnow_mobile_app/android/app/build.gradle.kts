import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is driven by android/key.properties, which is NOT in
// git — it names a keystore and carries its passwords. Create it from
// android/key.properties.example once, and every release build from then
// on is signed with the upload key Google Play expects.
//
// Without that file the build still works and still produces an APK, but
// one signed with the shared debug key. Play refuses those, so the build
// says so out loud rather than letting someone discover it at upload.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "ba.vetnow.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Real application id. Google Play refuses anything under
        // "com.example", so the default Flutter placeholder could never
        // have been published.
        applicationId = "ba.vetnow.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8: strips unreachable Java/Kotlin and rewrites what is
            // left, and shrinkResources drops the drawables and strings
            // that nothing references any more. Flutter's own Dart code
            // is already tree-shaken by the AOT compiler; this is the
            // other half, the Android side.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Fails nothing, but makes the debug-key situation impossible to miss.
if (!hasReleaseKeystore) {
    project.gradle.taskGraph.whenReady {
        if (allTasks.any { it.name.contains("Release") }) {
            logger.warn(
                "\n  VetNow: no android/key.properties — this release build is signed with the\n" +
                "  DEBUG key and Google Play will reject it. See android/key.properties.example.\n",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
