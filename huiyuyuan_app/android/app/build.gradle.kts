plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun readPropertiesFile(filePath: String): Map<String, String> {
    val f = rootProject.file(filePath)
    if (!f.exists()) return emptyMap()
    return f.readLines()
        .filter { it.isNotBlank() && it.contains("=") }
        .associate { line ->
            val parts = line.split("=", limit = 2)
            parts[0].trim() to parts[1].trim()
        }
}

val keystoreProps = readPropertiesFile("key.properties")
val localProps = readPropertiesFile("local.properties")
val merged = localProps + keystoreProps
val keystoreProperties: Map<String, String>? = if (merged.containsKey("storePassword")) merged else null

if (keystoreProperties != null) {
    println("[signing] ✓ key.properties found — release signing enabled")
} else {
    println("[signing] ✗ key.properties not found — using debug signing for release")
}

android {
    namespace = "com.huiyuyuan.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.huiyuyuan.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val props = keystoreProperties
            if (props != null) {
                keyAlias = props.getValue("keyAlias")
                keyPassword = props.getValue("keyPassword")
                storeFile = file(props.getValue("storeFile"))
                storePassword = props.getValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            val props = keystoreProperties
            signingConfig = if (props != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
