import java.util.Properties

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.potato.potato_todo"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // The application ID is stable for published installs.
        applicationId = "com.potato.potato_todo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.create("release").apply {
                keyAlias = signingProperties["keyAlias"] as String?
                keyPassword = signingProperties["keyPassword"] as String?
                storeFile = (signingProperties["storeFile"] as String?)?.let(::file)
                storePassword = signingProperties["storePassword"] as String?
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
