// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    // Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.2" apply false

    // Correct Kotlin plugin version
    id("org.jetbrains.kotlin.android") version "2.1.10" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ensure consistent build directory structure
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure app module is evaluated first
    project.evaluationDependsOn(":app")
}

// Register a clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
