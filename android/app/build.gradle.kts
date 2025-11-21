import java.util.Properties

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
        minSdk = flutter.minSdkVersion
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
            storeFile = rootProject.file(keystoreProperties["storeFile"]?.toString() ?: "upload-key.jks")
            storePassword = keystoreProperties["storePassword"]?.toString() ?: "123456"
            keyAlias = keystoreProperties["keyAlias"]?.toString() ?: "upload"
            keyPassword = keystoreProperties["keyPassword"]?.toString() ?: "123456"
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
