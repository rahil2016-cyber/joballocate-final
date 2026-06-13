import org.gradle.api.file.Directory
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Kotlin incremental compile breaks on Windows when Pub cache (C:) and project (e.g. F:) differ.
    tasks.withType<KotlinCompile>().configureEach {
        incremental = false
    }
}

// Flutter tooling looks for APKs under <project>/build/app/outputs/flutter-apk/ — not android/app/build/.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
