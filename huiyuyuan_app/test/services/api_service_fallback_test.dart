import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/services/api_service.dart';

void main() {
  group('ApiService production IP fallback', () {
    test('retries production HTTPS connection errors through fixed IP', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/api/health',
          baseUrl: ApiConfig.productionUrl,
        ),
        type: DioExceptionType.connectionError,
        error: const SocketException('Connection reset by peer'),
      );

      expect(ApiService.shouldUseProductionIpFallbackFor(error), isTrue);
    });

    test('does not retry requests that already used the IP fallback', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/api/health',
          baseUrl: ApiConfig.productionUrl,
          extra: const {'production_ip_fallback_attempted': true},
        ),
        type: DioExceptionType.connectionError,
        error: const SocketException('Connection reset by peer'),
      );

      expect(ApiService.shouldUseProductionIpFallbackFor(error), isFalse);
    });

    test('trusts only the pinned production certificate for fallback IP', () {
      final cert = _FakeX509Certificate(
        sha1: Uint8List.fromList(const <int>[
          216,
          50,
          75,
          115,
          143,
          37,
          74,
          66,
          204,
          19,
          190,
          107,
          75,
          92,
          134,
          144,
          12,
          227,
          10,
          33,
        ]),
        subject: '/CN=xn--lsws2cdzg.top',
        issuer: '/C=US/O=Let\'s Encrypt/CN=R13',
      );

      expect(
        ApiService.trustsProductionIpFallbackCertificate(
          cert,
          ApiConfig.productionIpAddress,
          443,
        ),
        isTrue,
      );
      expect(
        ApiService.trustsProductionIpFallbackCertificate(
          cert,
          '203.0.113.10',
          443,
        ),
        isFalse,
      );
    });
  });
}

class _FakeX509Certificate implements X509Certificate {
  _FakeX509Certificate({
    required this.sha1,
    required this.subject,
    required this.issuer,
  });

  @override
  final Uint8List sha1;

  @override
  final String subject;

  @override
  final String issuer;

  @override
  Uint8List get der => Uint8List(0);

  @override
  String get pem => '';

  @override
  DateTime get startValidity => DateTime.utc(2026, 3, 24);

  @override
  DateTime get endValidity => DateTime.utc(2026, 6, 22, 15, 7, 5);
}
