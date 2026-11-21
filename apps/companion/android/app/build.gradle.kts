plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "it.rasgeth.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (G40.10) needs the newer Java APIs on older Androids.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Rasgeth's own id (plan 3.9.0, choice 6): a new install, paired anew; the Kotlin package
        // (src/main/kotlin/it/rasgeth/app) follows the namespace.
        applicationId = "it.rasgeth.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 32-bit x86 runs only on old emulators: its copy of Vosk (10 MB) stays out of the APK.
    packaging {
        jniLibs {
            excludes += "lib/x86/libvosk.so"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // The wake word on the phone (G42.16): Vosk's own libvosk.so for each ABI (Apache-2.0), called
    // through dart:ffi (lib/voice/hands_free/vosk.dart); only the AAR, never its JNA bindings.
    implementation("com.alphacephei:vosk-android:0.3.47@aar")
}

// UnifiedPush's connector (G40.10) brings Tink for the JVM, flutter_secure_storage Tink for
// Android: the same classes twice. tink-android has them all, so the JVM one goes.
configurations.all {
    exclude(group = "com.google.crypto.tink", module = "tink")
}
