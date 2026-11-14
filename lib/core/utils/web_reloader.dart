import 'web_reloader_stub.dart'
    if (dart.library.html) 'web_reloader_web.dart';

/// Recarga forzadamente la aplicación web desregistrando/actualizando service workers.
void triggerWebPageReload() {
  reloadWebPage();
}
