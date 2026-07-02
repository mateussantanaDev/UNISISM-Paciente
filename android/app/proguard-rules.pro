# UNISISM Paciente — ProGuard/R8 rules pro build de produção.

# Flutter base (Material/Cupertino, plugins core)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# OkHttp/conscrypt (usado por alguns plugins de rede)
-dontwarn org.conscrypt.**
-dontwarn okhttp3.**

# permission_handler — reflection
-keep class com.baseflow.permissionhandler.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# open_filex
-keep class com.crazecoder.openfile.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Manter classes do nosso app (modelos serializados via fromJson)
-keep class br.gov.unisism.unisism_paciente.** { *; }
