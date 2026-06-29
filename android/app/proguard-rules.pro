# Regras padrão — mantém classes do Flutter e plugins comuns.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications — evita que o R8 remova classes usadas via
# reflexão para agendamento de notificações e boot receiver.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Flutter Play Store split install (deferred components) — não usamos esse
# recurso, então essas classes do Play Core nunca existem no classpath.
# Sem isso o R8 falha com "Missing class" porque o engine do Flutter as
# referencia condicionalmente mesmo sem a dependência estar presente.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# image_cropper (uCrop) — mantém as classes nativas da lib de recorte.
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**
