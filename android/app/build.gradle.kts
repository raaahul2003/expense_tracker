plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android") // Correct Kotlin plugin name
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.expense_tracker"
    compileSdk = 35  // Ensure you use a valid SDK version (update if needed)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.expense_tracker"
        minSdk = 23
        targetSdk = 35  // Ensure target SDK is a valid number
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))

    // Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}

flutter {
    source = "../.."
}
