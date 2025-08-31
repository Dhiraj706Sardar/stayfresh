plugins {

  // ...


  // Add the dependency for the Google services Gradle plugin

  id("com.google.gms.google-services") version "4.4.3" apply false

}
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Fix namespace issues for plugins that don't specify it
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                if (namespace == null) {
                    when (project.name) {
                        "flutter_barcode_scanner" -> namespace = "com.amolg.flutterbarcodescanner"
                        else -> namespace = "com.${project.name.replace("-", "_")}"
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}