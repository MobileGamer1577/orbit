import java.io.File
import java.util.Properties

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) keyProperties.load(keyPropertiesFile.inputStream())

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.orbit.tracker.orbit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.orbit.tracker.orbit"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"].toString()
            keyPassword = keyProperties["keyPassword"].toString()
            storeFile = file(keyProperties["storeFile"].toString())
            storePassword = keyProperties["storePassword"].toString()
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// =========================================================
// FIX: Flutter kann den APK-Output-Pfad nicht finden.
// Wir kopieren nach dem Build die APK in den von Flutter
// erwarteten Pfad: build/app/outputs/flutter-apk/
// =========================================================

val flutterExpectedDir = File(rootProject.projectDir, "../build/app/outputs/flutter-apk")

// --- DEBUG ---
val copyDebugApk = tasks.register("copyDebugApkToFlutterExpectedDir") {
    doLast {
        flutterExpectedDir.mkdirs()
        val buildDir = project.layout.buildDirectory.get().asFile
        val candidates = listOf(
            File(buildDir, "outputs/flutter-apk/app-debug.apk"),
            File(buildDir, "outputs/apk/debug/app-debug.apk")
        )
        val src = candidates.firstOrNull { it.exists() } ?: return@doLast
        val dst = File(flutterExpectedDir, "app-debug.apk")
        src.copyTo(dst, overwrite = true)
        println("✅ Copied Debug APK: ${src.absolutePath} -> ${dst.absolutePath}")
    }
}

tasks.matching { it.name.equals("assembleDebug", ignoreCase = true) }.configureEach {
    finalizedBy(copyDebugApk)
}

// --- RELEASE ---
val copyReleaseApk = tasks.register("copyReleaseApkToFlutterExpectedDir") {
    doLast {
        flutterExpectedDir.mkdirs()
        val buildDir = project.layout.buildDirectory.get().asFile
        val candidates = listOf(
            File(buildDir, "outputs/flutter-apk/app-release.apk"),
            File(buildDir, "outputs/apk/release/app-release.apk")
        )
        val src = candidates.firstOrNull { it.exists() } ?: return@doLast
        val dst = File(flutterExpectedDir, "app-release.apk")
        src.copyTo(dst, overwrite = true)
        println("✅ Copied Release APK: ${src.absolutePath} -> ${dst.absolutePath}")
    }
}

tasks.matching { it.name.equals("assembleRelease", ignoreCase = true) }.configureEach {
    finalizedBy(copyReleaseApk)
}