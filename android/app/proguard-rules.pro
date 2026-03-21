
# Flutter/Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-dontwarn io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry

# Firebase
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.firebase-auth.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.internal.firebase-auth.**

# ML Kit Document Scanner & dependencies
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.** { *; }
-keep class com.google.mlkit.vision.documentscanner.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_common.**
-keep class com.google.android.gms.internal.mlkit_vision_document_scanner.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_document_scanner.**

# Needed by an internal library of the scanner.
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzd {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zze {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzh {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzi {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzj {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzk {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzt {*;}
-keep class com.google.android.gms.internal.mlkit_vision_internal_vkp.zzu {*;}

# ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-dontwarn com.google.mlkit.vision.text.devanagari.**
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-dontwarn com.google.mlkit.vision.text.japanese.**
-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**

# Desugaring
-dontwarn com.android.tools.desugar.runtime.**
