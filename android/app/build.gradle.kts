import java.io.File

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

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

/* =========================================================
   FIX: Flutter findet manchmal das APK nicht (Output-Pfad).
   Wir kopieren nach dem Debug-Build das APK zusätzlich nach:
   <projectRoot>/build/app/outputs/flutter-apk/app-debug.apk
========================================================= */

val flutterExpectedDir = File(rootProject.projectDir, "../build/app/outputs/flutter-apk")

val copyDebugApkToFlutterExpectedDir = tasks.register("copyDebugApkToFlutterExpectedDir") {
    doLast {
        flutterExpectedDir.mkdirs()

        val candidates = listOf(
            File(project.buildDir, "outputs/flutter-apk/app-debug.apk"),
            File(project.buildDir, "outputs/apk/debug/app-debug.apk")
        )

        val src = candidates.firstOrNull { it.exists() }
            ?: throw GradleException(
                "APK nicht gefunden. Gesucht wurde:\n" +
                    candidates.joinToString("\n") { " - ${it.absolutePath}" }
            )

        val dst = File(flutterExpectedDir, "app-debug.apk")
        src.copyTo(dst, overwrite = true)

        println("✅ Copied APK for Flutter: ${src.absolutePath} -> ${dst.absolutePath}")
    }
}

/*
  WICHTIG: Nicht tasks.named("assembleDebug") benutzen (kann zu früh sein),
  sondern robust an alle Tasks anhängen, sobald sie existieren.
*/
tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy(copyDebugApkToFlutterExpectedDir)
}

// Falls Flutter/AGP bei dir den Task anders registriert, hilft oft auch das:
tasks.matching { it.name.equals("assembleDebug", ignoreCase = true) }.configureEach {
    finalizedBy(copyDebugApkToFlutterExpectedDir)
}