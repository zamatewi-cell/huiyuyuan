/// Cross-platform URL launcher utility.
library;

export 'url_helper_web.dart' if (dart.library.io) 'url_helper_native.dart';
