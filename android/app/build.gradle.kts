import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

val local = Properties().also { config ->
    rootProject.file("local.properties").takeIf { it.isFile }?.inputStream()?.use(config::load)
}

fun config(name: String, default: String = ""): String =
    providers.gradleProperty(name).orNull ?: local.getProperty(name, default)

fun stringLiteral(value: String): String = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

val copyHomeReference by tasks.registering(Sync::class) {
    from(rootProject.file("../docs/design/home-aprovada.png"))
    into(layout.buildDirectory.dir("generated/home-reference"))
}

android {
    namespace = "com.flops23.assistae"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.flops23.assistae"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"

        buildConfigField("String", "SUPABASE_URL", stringLiteral(config("assistae.supabase.url", "https://siizxjtyaphwjfdjsgom.supabase.co")))
        val publicKey = config("assistae.supabase.publicKey")
        require(publicKey.isEmpty() || publicKey.startsWith("sb_publishable_")) { "Use somente a chave publicável do Supabase" }
        buildConfigField("String", "SUPABASE_PUBLIC_KEY", stringLiteral(publicKey))
        buildConfigField("String", "FIREBASE_APP_ID", stringLiteral(config("assistae.firebase.appId")))
        buildConfigField("String", "FIREBASE_PROJECT_ID", stringLiteral(config("assistae.firebase.projectId")))
        buildConfigField("String", "FIREBASE_API_KEY", stringLiteral(config("assistae.firebase.apiKey")))
        buildConfigField("String", "FIREBASE_SENDER_ID", stringLiteral(config("assistae.firebase.senderId")))
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets.named("main") {
        assets.srcDir(layout.buildDirectory.dir("generated/home-reference"))
    }
}
tasks.named("preBuild") { dependsOn(copyHomeReference) }
kotlin { jvmToolchain(17) }

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.09.01")
    implementation(composeBom)
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.4")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended:1.7.8")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.media3:media3-exoplayer:1.8.0")
    implementation("androidx.media3:media3-exoplayer-hls:1.8.0")
    implementation("androidx.media3:media3-session:1.8.0")
    implementation("androidx.media3:media3-ui:1.8.0")
    implementation("androidx.media3:media3-datasource-okhttp:1.8.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.firebase:firebase-messaging:26.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    testImplementation("junit:junit:4.13.2")
}
