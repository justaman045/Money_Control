# ML Kit Text Recognition Keep Rules
-keep class com.google.mlkit.vision.text.** { *; }

# The app ships only the Latin text recognizer. The chinese/devangari/japanese/
# korean modules are excluded from the build (see build.gradle.kts), but
# google_mlkit_text_recognition still references their option classes from a
# runtime switch. Silence R8 on those — the branches are dead at runtime and
# the classes are intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
