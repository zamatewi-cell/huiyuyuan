/// Web platform URL launcher using dart:html.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Opens a URL by navigating the browser window to it.
void openUrl(String url) {
  html.window.location.href = url;
}
