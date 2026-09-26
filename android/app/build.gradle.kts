import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials live in android/key.properties, which is
// gitignored (see android/.gitignore). Fill that file in with your keystore
// details; while it is missing or any value is still blank, release builds
// fall back to the debug keystore so `flutter run --release` and CI keep
// working.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseStoreFile = keystoreProperties.getProperty("storeFile", "")
val releaseStorePassword = keystoreProperties.getProperty("storePassword", "")
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias", "")
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword", "")
val hasReleaseSigning =
    releaseStoreFile.isNotBlank() &&
        releaseStorePassword.isNotBlank() &&
        releaseKeyAlias.isNotBlank() &&
        releaseKeyPassword.isNotBlank()

android {
    namespace = "io.github.tlw00988.sonata"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.tlw00988.sonata"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 启动器里的应用名，来自 AndroidManifest 的 ${appName}；debug 构建在
        // 下面覆盖成别的名字，方便区分两个同时装着的包。
        manifestPlaceholders["appName"] = "Sonata"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
        debug {
            // 调试包用独立包名，跟正式包在设备上并存，互不覆盖；连带启动器
            // 里也换个名字，否则两个图标长得一模一样分不清。
            // 注意：首装后原来那份调试包里的服务器地址 / 凭据不会自动搬过来
            // （shared_preferences 与 flutter_secure_storage 都是按包名隔离的）。
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Sonata Debug"
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
