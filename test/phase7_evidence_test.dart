import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rekadana_mobile/features/expenses/expense_detail_screen.dart';
import 'package:rekadana_mobile/features/expenses/expense_service.dart';
import 'package:rekadana_mobile/features/expenses/models/expense_request_model.dart';
import 'package:rekadana_mobile/features/organization/models/organization_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 7 Mobile - Pengujian Bukti Transaksi & Penyimpanan Privat', () {
    test('EvidenceModel.fromJson: Parsing atribut bukti transaksi dan format ukuran', () {
      final jsonSmall = {
        'id': 'ev-1',
        'originalFileName': 'struk_toko.jpg',
        'detectedFileType': 'jpeg',
        'fileSizeBytes': 512,
        'createdAt': '2026-10-30T10:00:00Z',
      };
      final itemSmall = EvidenceModel.fromJson(jsonSmall);
      expect(itemSmall.id, 'ev-1');
      expect(itemSmall.originalFileName, 'struk_toko.jpg');
      expect(itemSmall.detectedFileType, 'jpeg');
      expect(itemSmall.fileSizeBytes, 512);
      expect(itemSmall.formattedSize, '512 B');

      final jsonKb = {
        'id': 'ev-2',
        'originalFileName': 'nota_konsumsi.png',
        'detectedFileType': 'png',
        'fileSizeBytes': 1024 * 350, // 350 KB
        'createdAt': '2026-10-30T10:05:00Z',
      };
      final itemKb = EvidenceModel.fromJson(jsonKb);
      expect(itemKb.formattedSize, '350.0 KB');

      final jsonMb = {
        'id': 'ev-3',
        'originalFileName': 'laporan_kwitansi.pdf',
        'detectedFileType': 'pdf',
        'fileSizeBytes': (1024 * 1024 * 3.5).toInt(), // 3.5 MB
        'createdAt': '2026-10-30T10:10:00Z',
      };
      final itemMb = EvidenceModel.fromJson(jsonMb);
      expect(itemMb.formattedSize, '3.5 MB');
    });

    test('Batas konstanta ukuran file bukti kMaxEvidenceBytes tepat 5 MiB (5.242.880 byte)', () {
      expect(kMaxEvidenceBytes, 5242880);
      expect(kMaxEvidenceBytes, 5 * 1024 * 1024);
    });

    testWidgets('ExpenseDetailScreen: Menampilkan komponen Bukti Transaksi dan daftar berkas', (tester) async {
      final testExpense = ExpenseRequestModel(
        id: 'exp-test-1',
        eventId: 'event-1',
        title: 'Pengadaan ATK Kegiatan',
        requestedAmount: '150000.00',
        approvedAmount: '150000.00',
        status: 'approved',
        createdAt: '2026-10-30T09:00:00Z',
      );

      final testOrg = OrganizationModel(
        id: 'org-test-1',
        name: 'SMK Negeri 1 Test',
        slug: 'smkn-1-test',
        role: 'panitia_anggota',
      );

      final detail = ExpenseRequestDetailModel(
        request: testExpense,
        payments: [],
        summary: ExpenseSummaryModel(
          requestedAmount: 150000,
          approvedAmount: 150000,
          totalPaidNet: 0,
          remainingBalance: 150000,
          isFullyPaid: false,
          paymentCount: 0,
        ),
      );

      final mockEvidence = [
        EvidenceModel(
          id: 'ev-test-1',
          originalFileName: 'nota_pembelian_atk.jpg',
          detectedFileType: 'jpeg',
          fileSizeBytes: 204800,
          createdAt: '2026-10-30T09:15:00Z',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseDetailScreen(
            expense: testExpense,
            organization: testOrg,
            initialDetail: detail,
            initialEvidence: mockEvidence,
          ),
        ),
      );

      await tester.pump();

      // Memeriksa keberadaan judul section bukti
      expect(find.text('Bukti Transaksi / Nota'), findsOneWidget);

      // Memeriksa file bukti tertera
      expect(find.text('nota_pembelian_atk.jpg'), findsOneWidget);
      expect(find.text('200.0 KB'), findsOneWidget);

      // Memeriksa tombol aksi lampirkan bukti baru dan tombol buka
      expect(find.text('Buka'), findsOneWidget);
      expect(find.text('Lampirkan Bukti Baru'), findsOneWidget);
    });
  });
}
