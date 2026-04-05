import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('ApiService initialize is safe under concurrent calls', () async {
    final service = ApiService.forTesting(initialized: false);

    await Future.wait<void>([
      service.initialize(),
      service.initialize(),
      service.initialize(),
    ]);

    expect(service.isLoggedIn, isFalse);

    await service.initialize();
    expect(service.isLoggedIn, isFalse);
  });
}
