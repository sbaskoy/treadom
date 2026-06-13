import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imza bilgileri android/key.properties'ten okunur (repoya GİRMEZ;
// .gitignore'da). Dosya yoksa (ör. başka makinede) release build debug
// anahtarıyla imzalanır — böylece `flutter run --release` yine çalışır, ama
// Play'e yüklenecek sürüm bu dosyayla imzalanmalıdır.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.salimbaskoy.treadom"
    compileSdk = flutter.compileSdkVersion
    // Firebase, geolocator, google_mobile_ads vb. eklentiler NDK 27 gerektirdiği
    // için sürümü sabitliyoruz (NDK sürümleri geriye dönük uyumludur).
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications (java.time tabanlı zamanlanmış bildirimler)
        // eski Android sürümlerinde core library desugaring gerektirir.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.salimbaskoy.treadom"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // google_mobile_ads en az Android 6 (API 23) gerektirir.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties varsa gerçek release anahtarıyla, yoksa (yerel test
            // için) debug anahtarıyla imzala.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // core library desugaring (flutter_local_notifications için gerekli).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
