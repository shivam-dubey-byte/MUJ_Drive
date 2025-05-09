import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing info from android/key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.muj_drive"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias     = keystoreProperties["keyAlias"]     as String
            keyPassword  = keystoreProperties["keyPassword"]  as String
            // <-- resolve the JKS path relative to android/, not android/app/
            storeFile    = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword= keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.example.muj_drive"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // use your release keystore instead of debug
            signingConfig    = signingConfigs.getByName("release")
            isMinifyEnabled  = true          // optional: run R8/ProGuard
            isShrinkResources= true          // optional: strip unused resources
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // continue using the debug key for debug builds
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
