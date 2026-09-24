allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ce bloc DOIT être avant evaluationDependsOn(":app") ci-dessous, sinon ":app"
// est déjà évalué quand on essaie d'y accrocher afterEvaluate.
//
// IMPORTANT : on ne relève que les sous-modules dont le compileSdk est
// INFÉRIEUR à 36 (ex. flutter_native_splash resté à 31). On ne redescend
// jamais un module qui demande déjà plus haut (ex. permission_handler_android
// à 37, qui utilise de vrais symboles Android 17 comme ACCESS_LOCAL_NETWORK —
// les y forcer à 36 casserait sa compilation).
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.let { android ->
            val currentApi = android.compileSdkVersion
                ?.substringAfterLast('-')
                ?.toIntOrNull()
                ?: 0
            if (currentApi in 1 until 36) {
                android.compileSdkVersion(36)
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