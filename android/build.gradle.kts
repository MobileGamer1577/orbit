allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter/Gradle erwartet dieses clean-Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}