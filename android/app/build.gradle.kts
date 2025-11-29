import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
} else {
    println("⚠️ key.properties not found at ${keystorePropertiesFile.path}")
}

android {
    namespace = "com.mashiur.expenseapp" // ✅ Unique namespace
    compileSdk = 36

    defaultConfig {
        applicationId = "com.mashiur.expenseapp" // ✅ Unique applicationId
        minSdk = 23
        targetSdk = 36
        // Read from pubspec.yaml: e.g., version: 1.0.1+2
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            val desiredStoreFile = rootProject.file(keystoreProperties["storeFile"]?.toString() ?: "upload-key.jks")
            val hasDesiredKeystore = desiredStoreFile.exists()

            // Fallback to Android debug keystore if release keystore missing
            val debugKeystore = File(System.getProperty("user.home"), ".android/debug.keystore")
            val useDebugKeystore = !hasDesiredKeystore && debugKeystore.exists()

            if (!hasDesiredKeystore) {
                println("⚠️ Release keystore not found at ${desiredStoreFile.path}")
                if (useDebugKeystore) {
                    println("ℹ️ Falling back to debug keystore at ${debugKeystore.path} for local build")
                } else {
                    println("❌ Debug keystore not found at ${debugKeystore.path}. Please create or provide a release keystore.")
                }
            }

            storeFile = if (useDebugKeystore) debugKeystore else desiredStoreFile
            storePassword = if (useDebugKeystore) "android" else (keystoreProperties["storePassword"]?.toString() ?: "123456")
            keyAlias = if (useDebugKeystore) "androiddebugkey" else (keystoreProperties["keyAlias"]?.toString() ?: "upload")
            keyPassword = if (useDebugKeystore) "android" else (keystoreProperties["keyPassword"]?.toString() ?: "123456")
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for core library desugaring support
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
