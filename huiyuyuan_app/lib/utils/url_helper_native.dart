/// Native platform URL launcher using url_launcher.
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in the external browser.
void openUrl(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
