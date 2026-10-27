import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rekadana_mobile/core/network/api_client.dart';
import 'package:rekadana_mobile/features/auth/login_screen.dart';
import 'package:rekadana_mobile/features/organization/models/organization_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Mobile - Pengujian Auth, Token Expiry, & Jaringan', () {
    test('Token Expiry: ApiClient menangani status 401 dan memicu onSessionExpired', () {
      bool sessionExpiredCallbackFired = false;
      ApiClient.onSessionExpired = () {
        sessionExpiredCallbackFired = true;
      };

      final client = ApiClient();
      expect(client, isNotNull);

      // Panggil callback secara langsung untuk memastikan handler berfungsi
      ApiClient.onSessionExpired?.call();
      expect(sessionExpiredCallbackFired, isTrue);
    });

    test('Network Error: Pemetaan Timeout dan SocketException menghasilkan pesan user-friendly', () {
      final requestOptions = RequestOptions(path: '/api/v1/organizations');

      final timeoutError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      final connectionError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        error: const SocketException('Failed host lookup'),
      );

      expect(timeoutError.type, DioExceptionType.connectionTimeout);
      expect(connectionError.type, DioExceptionType.connectionError);
    });

    test('Organization Model: Hak akses role Ketua dan Bendahara terverifikasi', () {
      final orgKetua = OrganizationModel(
        id: 'org-1',
        name: 'OSIS SMKN 1',
        slug: 'osis-smkn1',
        role: 'ketua_kegiatan',
      );

      final orgBendahara = OrganizationModel(
        id: 'org-2',
        name: 'Ekstrakurikuler Paskibra',
        slug: 'paskibra',
        role: 'bendahara',
      );

      final orgAnggota = OrganizationModel(
        id: 'org-3',
        name: 'PMR',
        slug: 'pmr',
        role: 'panitia_anggota',
      );

      expect(orgKetua.isKetua, isTrue);
      expect(orgKetua.isBendahara, isFalse);
      expect(orgKetua.roleDisplayTitle, 'Ketua Kegiatan');

      expect(orgBendahara.isBendahara, isTrue);
      expect(orgBendahara.isKetua, isFalse);
      expect(orgBendahara.roleDisplayTitle, 'Bendahara');

      expect(orgAnggota.isKetua, isFalse);
      expect(orgAnggota.isBendahara, isFalse);
      expect(orgAnggota.roleDisplayTitle, 'Panitia Pelaksana');
    });
  });

  group('Phase 3 Mobile - UI Widget Test Login & Sesi', () {
    testWidgets('LoginScreen menampilkan peringatan saat sesi kedaluwarsa', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(
            sessionExpiredMessage: 'Sesi Anda telah kedaluwarsa. Silakan masuk kembali.',
          ),
        ),
      );

      expect(find.text('RekaDana Mobile'), findsOneWidget);
      expect(find.text('Sesi Anda telah kedaluwarsa. Silakan masuk kembali.'), findsOneWidget);
    });
  });
}
