library;

class LocalDebugConfig {
  LocalDebugConfig._();

  static final LocalDebugConfig instance = LocalDebugConfig._();

  String? get loadedFromPath => null;
  String? get loadError => null;

  Future<void> load() async {}

  String? getString(String key) => null;

  bool? getBool(String key) => null;

  void replaceValuesForTesting(
    Map<String, dynamic> values, {
    String? loadedFromPath,
    String? loadError,
  }) {}

  void clearForTesting() {}
}
