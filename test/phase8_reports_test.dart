import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rekadana_mobile/features/expenses/expense_list_screen.dart';
import 'package:rekadana_mobile/features/expenses/models/expense_request_model.dart';
import 'package:rekadana_mobile/features/organization/events_list_screen.dart';
import 'package:rekadana_mobile/features/organization/models/event_model.dart';
import 'package:rekadana_mobile/features/organization/models/organization_model.dart';
import 'package:rekadana_mobile/features/organization/models/report_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 8 Mobile - Pengujian Laporan, Ringkasan Finansial, dan Status Summary', () {
    test('BudgetVsActualReportModel.fromJson: Parsing atribut laporan anggaran vs realisasi', () {
      final jsonReport = {
        'eventId': 'ev-test-1',
        'eventName': 'Seminar Nasional 2026',
        'availableFunds': '10000000.00',
        'hasActiveBudget': true,
        'activeBudgetVersionNumber': 1,
        'approvedBudgetTotal': '5000000.00',
        'actualNet': '2400000.00',
        'openCommitments': '400000.00',
        'remainingControlBudget': '2200000.00',
        'itemsBreakdown': [
          {
            'budgetItemId': 'item-1',
            'name': 'Konsumsi Peserta & Panitia',
            'category': 'Konsumsi',
            'budgetTotal': '3500000.00',
            'actualNet': '2000000.00',
            'openCommitments': '0.00',
            'remaining': '1500000.00',
          },
          {
            'budgetItemId': 'item-2',
            'name': 'Penggandaan Modul',
            'category': 'Perlengkapan',
            'budgetTotal': '1500000.00',
            'actualNet': '400000.00',
            'openCommitments': '400000.00',
            'remaining': '700000.00',
          },
        ],
      };

      final report = BudgetVsActualReportModel.fromJson(jsonReport);

      expect(report.eventId, 'ev-test-1');
      expect(report.eventName, 'Seminar Nasional 2026');
      expect(report.hasActiveBudget, true);
      expect(report.activeBudgetVersionNumber, 1);
      expect(report.approvedBudgetTotal, '5000000.00');
      expect(report.actualNet, '2400000.00');
      expect(report.openCommitments, '400000.00');
      expect(report.remainingControlBudget, '2200000.00');
      expect(report.itemsBreakdown.length, 2);

      final itemKonsumsi = report.itemsBreakdown[0];
      expect(itemKonsumsi.budgetItemId, 'item-1');
      expect(itemKonsumsi.name, 'Konsumsi Peserta & Panitia');
      expect(itemKonsumsi.category, 'Konsumsi');
      expect(itemKonsumsi.budgetTotal, '3500000.00');
      expect(itemKonsumsi.actualNet, '2000000.00');
      expect(itemKonsumsi.openCommitments, '0.00');
      expect(itemKonsumsi.remaining, '1500000.00');

      final itemModul = report.itemsBreakdown[1];
      expect(itemModul.name, 'Penggandaan Modul');
      expect(itemModul.remaining, '700000.00');
    });

    testWidgets('ExpenseListScreen: Menampilkan ringkasan status pengeluaran', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testOrg = OrganizationModel(
        id: 'org-test-1',
        name: 'SMK Test Organisasi',
        slug: 'smk-test',
        role: 'bendahara',
      );

      final testEvent = EventModel(
        id: 'ev-test-1',
        organizationId: 'org-test-1',
        name: 'Seminar Nasional 2026',
        availableFunds: '10000000.00',
        participantCount: 100,
        status: 'active',
      );

      final mockExpenses = [
        ExpenseRequestModel(
          id: 'exp-1',
          eventId: 'ev-test-1',
          title: 'Konsumsi Rapat Panitia',
          requestedAmount: '500000.00',
          approvedAmount: '500000.00',
          status: 'approved',
          createdAt: '2026-10-30T09:00:00Z',
        ),
        ExpenseRequestModel(
          id: 'exp-2',
          eventId: 'ev-test-1',
          title: 'Pembelian Banner',
          requestedAmount: '200000.00',
          status: 'submitted',
          createdAt: '2026-10-30T10:00:00Z',
        ),
        ExpenseRequestModel(
          id: 'exp-3',
          eventId: 'ev-test-1',
          title: 'Sewa Speaker Aktif',
          requestedAmount: '350000.00',
          approvedAmount: '350000.00',
          status: 'paid',
          createdAt: '2026-10-30T11:00:00Z',
        ),
        ExpenseRequestModel(
          id: 'exp-4',
          eventId: 'ev-test-1',
          title: 'Honor Artis',
          requestedAmount: '10000000.00',
          status: 'rejected',
          createdAt: '2026-10-30T12:00:00Z',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseListScreen(
            organization: testOrg,
            event: testEvent,
            initialExpenses: mockExpenses,
          ),
        ),
      );

      await tester.pump();

      // Memeriksa label dan angka ringkasan status summary
      expect(find.text('Diajukan'), findsWidgets);
      expect(find.text('Disetujui'), findsWidgets);
      expect(find.text('Dibayar'), findsOneWidget);
      expect(find.text('Ditolak'), findsWidgets);

      // Memeriksa hitungan pada ringkasan status: masing-masing 1
      expect(find.text('1'), findsNWidgets(4)); // 1 Diajukan, 1 Disetujui, 1 Dibayar, 1 Ditolak

      // Memeriksa daftar item pengeluaran tampil
      expect(find.text('Konsumsi Rapat Panitia'), findsOneWidget);
      expect(find.text('Pembelian Banner'), findsOneWidget);
      expect(find.text('Sewa Speaker Aktif'), findsOneWidget);
      expect(find.text('Honor Artis'), findsOneWidget);
    });

    testWidgets('EventsListScreen: Menampilkan ringkasan finansial 4 metrik per kegiatan', (tester) async {
      final testOrg = OrganizationModel(
        id: 'org-test-1',
        name: 'Himpunan Mahasiswa Informatika',
        slug: 'hmi-teknik',
        role: 'bendahara',
      );

      final testEvent = EventModel(
        id: 'ev-test-1',
        organizationId: 'org-test-1',
        name: 'Olimpiade Pemrograman 2026',
        description: 'Kompetisi coding mahasiswa tingkat nasional',
        availableFunds: '10000000.00',
        participantCount: 150,
        status: 'active',
      );

      final testReport = BudgetVsActualReportModel(
        eventId: 'ev-test-1',
        eventName: 'Olimpiade Pemrograman 2026',
        availableFunds: '10000000.00',
        hasActiveBudget: true,
        activeBudgetVersionNumber: 1,
        approvedBudgetTotal: '5000000.00',
        actualNet: '2400000.00',
        openCommitments: '400000.00',
        remainingControlBudget: '2200000.00',
        itemsBreakdown: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EventsListScreen(
            organization: testOrg,
            initialEvents: [testEvent],
            initialReports: {
              'ev-test-1': testReport,
            },
          ),
        ),
      );

      await tester.pump();

      // Memeriksa header dan nama event
      expect(find.text('Olimpiade Pemrograman 2026'), findsOneWidget);
      expect(find.text('150 Peserta'), findsOneWidget);
      expect(find.text('Peran Anda: Bendahara'), findsOneWidget);

      // Memeriksa 4 label metrik finansial
      expect(find.text('Pagu Dana'), findsOneWidget);
      expect(find.text('Anggaran Resmi'), findsOneWidget);
      expect(find.text('Realisasi Bersih'), findsOneWidget);
      expect(find.text('Sisa Kontrol'), findsOneWidget);

      // Memeriksa format nominal mata uang rupiah
      expect(find.text('Rp10.000.000'), findsOneWidget);
      expect(find.text('Rp5.000.000'), findsOneWidget);
      expect(find.text('Rp2.400.000'), findsOneWidget);
      expect(find.text('Rp2.200.000'), findsOneWidget);

      // Memeriksa ketersediaan tombol navigasi penting
      expect(find.text('Scenario Lab (Simulasi Anggaran)'), findsOneWidget);
      expect(find.text('Versi Anggaran & Approval Bendahara'), findsOneWidget);
      expect(find.text('Ajukan Pengeluaran Lapangan'), findsOneWidget);
      expect(find.text('Daftar Pengeluaran'), findsOneWidget);
      expect(find.text('Review Bendahara'), findsOneWidget);
    });
  });
}
