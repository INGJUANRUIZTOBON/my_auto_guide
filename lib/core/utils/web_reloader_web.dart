// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Recarga la aplicación Web y actualiza los service workers si están disponibles.
void reloadWebPage() {
  try {
    if (html.window.navigator.serviceWorker != null) {
      html.window.navigator.serviceWorker!.getRegistrations().then((registrations) {
        for (final reg in registrations) {
          reg.update();
        }
      });
    }
  } catch (_) {}
  html.window.location.reload();
}
