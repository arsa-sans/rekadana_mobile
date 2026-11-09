import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rekadana_mobile/features/approval/bendahara_review_screen.dart';
import 'package:rekadana_mobile/features/auth/login_screen.dart';
import 'package:rekadana_mobile/features/auth/register_screen.dart';
import 'package:rekadana_mobile/features/expenses/expense_create_screen.dart';
import 'package:rekadana_mobile/features/expenses/expense_detail_screen.dart';
import 'package:rekadana_mobile/features/expenses/expense_list_screen.dart';
import 'package:rekadana_mobile/features/expenses/models/budget_item_model.dart';
import 'package:rekadana_mobile/features/expenses/models/expense_request_model.dart';
import 'package:rekadana_mobile/features/organization/events_list_screen.dart';
import 'package:rekadana_mobile/features/organization/models/event_model.dart';
import 'package:rekadana_mobile/features/organization/models/organization_model.dart';
import 'package:rekadana_mobile/features/organization/models/report_model.dart';
import 'package:rekadana_mobile/features/scenarios/scenario_create_screen.dart';
import 'package:rekadana_mobile/features/scenarios/scenario_item_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testOrgKetua = OrganizationModel(
    id: 'org-test-1',
    name: 'OSIS SMK Negeri 1 Jakarta',
    slug: 'osis-smkn1',
    role: 'ketua_kegiatan',
  );

  final testOrgBendahara = OrganizationModel(
    id: 'org-test-1',
    name: 'OSIS SMK Negeri 1 Jakarta',
    slug: 'osis-smkn1',
    role: 'bendahara',
  );

  final testOrgPanitia = OrganizationModel(
    id: 'org-test-1',
    name: 'OSIS SMK Negeri 1 Jakarta',
    slug: 'osis-smkn1',
    role: 'panitia_anggota',
  );

  final testEvent = EventModel(
    id: 'event-ldks-1',
    organizationId: 'org-test-1',
    name: 'LDKS 2026',
    description: 'Latihan Dasar Kepemimpinan Siswa 2026',
    participantCount: 120,
    availableFunds: '15000000.00',
    status: 'active',
  );

  final testReport = BudgetVsActualReportModel(
    eventId: testEvent.id,
    eventName: testEvent.name,
    availableFunds: '15000000.00',
    hasActiveBudget: true,
    activeBudgetVersionNumber: 1,
    approvedBudgetTotal: '9800000.00',
    actualNet: '3800000.00',
    openCommitments: '1000000.00',
    remainingControlBudget: '5000000.00',
    itemsBreakdown: [
      BudgetItemBreakdownModel(
        budgetItemId: 'item-konsumsi-1',
        name: 'Konsumsi Peserta dan Panitia',
        category: 'Konsumsi',
        budgetTotal: '6000000.00',
        actualNet: '3000000.00',
        openCommitments: '0.00',
        remaining: '3000000.00',
      ),
      BudgetItemBreakdownModel(
        budgetItemId: 'item-modul-1',
        name: 'Buku Panduan Modul',
        category: 'Perlengkapan',
        budgetTotal: '1800000.00',
        actualNet: '800000.00',
        openCommitments: '1000000.00',
        remaining: '0.00',
      ),
    ],
  );

  group('Fase 9 Mobile: Alur 1 (Registrasi, Login, dan Navigasi Auth)', () {
    testWidgets('LoginScreen menampilkan form login dan tautan pendaftaran akun', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Masuk ke Akun'), findsOneWidget);
      expect(find.text('Daftar akun baru'), findsOneWidget);

      await tester.tap(find.text('Daftar akun baru'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Akun RekaDana'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });

    testWidgets('RegisterScreen memvalidasi input formulir wajib', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pump();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    });
  });

  group('Fase 9 Mobile: Alur 2 (Kegiatan, Skenario, dan Form Item)', () {
    testWidgets('EventsListScreen menampilkan dialog Buat Kegiatan untuk role Ketua/Bendahara', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EventsListScreen(
            organization: testOrgKetua,
            initialEvents: [testEvent],
            initialReports: {testEvent.id: testReport},
          ),
        ),
      );

      expect(find.text('LDKS 2026'), findsOneWidget);
      expect(find.text('Buat Kegiatan'), findsOneWidget);

      await tester.tap(find.text('Buat Kegiatan'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Kegiatan Baru'), findsOneWidget);
      expect(find.text('Pagu Dana Tersedia (Rp)'), findsOneWidget);
      expect(find.text('Simpan Kegiatan'), findsOneWidget);
    });

    testWidgets('ScenarioCreateScreen memvalidasi input nama skenario', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioCreateScreen(
            organization: testOrgKetua,
            event: testEvent,
          ),
        ),
      );

      expect(find.text('Buat Skenario Baru'), findsOneWidget);
      await tester.tap(find.text('Simpan dan Tambah Item'));
      await tester.pump();

      expect(find.text('Nama skenario minimal 2 karakter.'), findsOneWidget);
    });

    testWidgets('ScenarioItemFormScreen memvalidasi nama kebutuhan barang dan jasa', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioItemFormScreen(
            organization: testOrgKetua,
            event: testEvent,
            scenarioId: 'sc-test-1',
            scenarioName: 'Skenario Optimal',
          ),
        ),
      );

      expect(find.text('Tambah Item Kebutuhan'), findsOneWidget);
      await tester.ensureVisible(find.text('Simpan Item Kebutuhan'));
      await tester.tap(find.text('Simpan Item Kebutuhan'));
      await tester.pump();

      expect(find.text('Nama kebutuhan minimal 2 karakter.'), findsOneWidget);
    });
  });

  group('Fase 9 Mobile: Alur 3 (Review Bendahara dan Pemisahan Tugas)', () {
    testWidgets('BendaharaReviewScreen menampilkan wadah review pengeluaran', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BendaharaReviewScreen(
            organization: testOrgBendahara,
            event: testEvent,
            initialRequests: const [],
          ),
        ),
      );

      expect(find.text('Review Pengeluaran Bendahara'), findsOneWidget);
      expect(find.text('Menunggu Review'), findsOneWidget);
      expect(find.text('Semua Riwayat'), findsOneWidget);
      expect(find.text('Semua Pengajuan Telah Direview'), findsOneWidget);
    });
  });

  group('Fase 9 Mobile: Alur 4 dan 5 (Pengeluaran, Bukti, dan Pembayaran)', () {
    testWidgets('ExpenseCreateScreen merender form pengajuan pengeluaran', (tester) async {
      final mockItems = [
        BudgetItemModel(
          id: 'item-1',
          name: 'Konsumsi Peserta',
          priority: 'required',
          estimatedUnitCost: '25000',
          quantity: '100',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseCreateScreen(
            organization: testOrgPanitia,
            event: testEvent,
            initialBudgetItems: mockItems,
          ),
        ),
      );

      expect(find.text('Pengajuan Kebutuhan Lapangan'), findsOneWidget);
      expect(find.text('Kirim Pengajuan Pengeluaran'), findsOneWidget);
    });

    testWidgets('ExpenseDetailScreen menampilkan status pembayaran dan riwayat transaksi', (tester) async {
      final expenseReq = ExpenseRequestModel(
        id: 'req-konsumsi-1',
        eventId: testEvent.id,
        budgetItemId: 'item-konsumsi-1',
        title: 'Uang Muka Katering Hari Pertama',
        description: 'Pembayaran DP 50% untuk katering',
        requestedAmount: '3000000.00',
        status: 'approved',
        requestedBy: 'user-panitia-1',
        createdAt: '2026-11-09T08:00:00.000Z',
      );

      final detail = ExpenseRequestDetailModel(
        request: expenseReq,
        payments: [
          PaymentModel(
            id: 'pay-1',
            amount: '3000000.00',
            postedBy: 'user-bendahara-1',
            postedByName: 'Bendahara Utama',
            postedAt: '2026-11-09T08:15:00.000Z',
            notes: 'Transfer bank',
            isReversed: false,
            idempotencyKey: 'IDEM-KEY-001',
            netAmount: 3000000.0,
            reversals: const [],
          ),
        ],
        summary: ExpenseSummaryModel(
          requestedAmount: 3000000.0,
          approvedAmount: 3000000.0,
          totalPaidNet: 3000000.0,
          remainingBalance: 0.0,
          isFullyPaid: true,
          paymentCount: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseDetailScreen(
            expense: expenseReq,
            organization: testOrgBendahara,
            initialDetail: detail,
            initialEvidence: const [],
          ),
        ),
      );

      expect(find.text('Uang Muka Katering Hari Pertama'), findsOneWidget);
      expect(find.text('Riwayat Pembayaran'), findsOneWidget);
      expect(find.text('1 transaksi'), findsOneWidget);
    });
  });

  group('Fase 9 Mobile: Alur 6 (Laporan Finansial dan Rekonsiliasi)', () {
    testWidgets('EventsListScreen menampilkan 4 metrik finansial per kegiatan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EventsListScreen(
            organization: testOrgBendahara,
            initialEvents: [testEvent],
            initialReports: {testEvent.id: testReport},
          ),
        ),
      );

      expect(find.text('Pagu Dana'), findsOneWidget);
      expect(find.text('Anggaran Resmi'), findsOneWidget);
      expect(find.text('Realisasi Bersih'), findsOneWidget);
      expect(find.text('Sisa Kontrol'), findsOneWidget);

      expect(find.text('Rp15.000.000'), findsOneWidget);
      expect(find.text('Rp9.800.000'), findsOneWidget);
      expect(find.text('Rp3.800.000'), findsOneWidget);
      expect(find.text('Rp5.000.000'), findsOneWidget);
    });

    testWidgets('ExpenseListScreen menampilkan ringkasan status pengeluaran', (tester) async {
      final requests = [
        ExpenseRequestModel(
          id: 'r1',
          eventId: testEvent.id,
          budgetItemId: 'i1',
          title: 'Konsumsi 1',
          requestedAmount: '1000000.00',
          status: 'submitted',
          createdAt: '2026-11-09T08:00:00.000Z',
        ),
        ExpenseRequestModel(
          id: 'r2',
          eventId: testEvent.id,
          budgetItemId: 'i1',
          title: 'Konsumsi 2',
          requestedAmount: '2000000.00',
          status: 'paid',
          createdAt: '2026-11-09T08:05:00.000Z',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseListScreen(
            organization: testOrgBendahara,
            event: testEvent,
            initialExpenses: requests,
          ),
        ),
      );

      expect(find.text('Diajukan'), findsWidgets);
      expect(find.text('Dibayar'), findsWidgets);
      expect(find.text('Konsumsi 1'), findsOneWidget);
      expect(find.text('Konsumsi 2'), findsOneWidget);
    });
  });
}
