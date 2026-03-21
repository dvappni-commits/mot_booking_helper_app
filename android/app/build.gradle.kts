import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Load keystore properties (android/key.properties)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.projectowner.dvapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.projectowner.dvapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Safe to include (Firebase/Ads can grow your app)
        multiDexEnabled = true
    }

    // ✅ Required for flutter_local_notifications (desugaring)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    // ✅ Proper Play Store signing
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String

                // key.properties: storeFile=upload-keystore.jks
                val storeFileName = keystoreProperties["storeFile"] as String

                // ✅ Make path robust: key.properties sits in /android, so resolve relative to /android
                storeFile = file(storeFileName)
            }
        }
    }

    buildTypes {
        release {
            // ✅ Use the release keystore (NOT debug)
            signingConfig = signingConfigs.getByName("release")

            // You can enable these later if you want shrinking/obfuscation
            isMinifyEnabled = false
            isShrinkResources = false
        }

        debug {
            // debug signing stays default
        }
    }
}

dependencies {
    // ✅ Required for core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ✅ Needed if multiDexEnabled=true
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}