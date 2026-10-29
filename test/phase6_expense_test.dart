import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rekadana_mobile/core/utils/currency_formatter.dart';
import 'package:rekadana_mobile/core/widgets/status_badge.dart';
import 'package:rekadana_mobile/features/expenses/expense_detail_screen.dart';
import 'package:rekadana_mobile/features/expenses/models/expense_request_model.dart';
import 'package:rekadana_mobile/features/organization/models/organization_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });
  group('Phase 6 Mobile - Pengujian Model Pengeluaran, Pembayaran & Reversal', () {
    test('ExpenseRequestModel.fromJson: Parsing atribut pengeluaran dan status boolean', () {
      final json = {
        'id': 'exp-1',
        'eventId': 'ev-1',
        'budgetVersionId': 'bv-1',
        'budgetItemId': 'bi-1',
        'requestedBy': 'user-panitia-1',
        'title': 'Konsumsi Rapat Panitia',
        'description': 'Snack untuk 20 orang',
        'requestedAmount': '350000.00',
        'approvedAmount': '300000.00',
        'status': 'partially_paid',
        'createdAt': '2026-10-29T10:00:00Z',
      };

      final expense = ExpenseRequestModel.fromJson(json);

      expect(expense.id, 'exp-1');
      expect(expense.eventId, 'ev-1');
      expect(expense.title, 'Konsumsi Rapat Panitia');
      expect(expense.requestedAmount, '350000.00');
      expect(expense.approvedAmount, '300000.00');
      expect(expense.status, 'partially_paid');
      expect(expense.isPartiallyPaid, isTrue);
      expect(expense.isPaid, isFalse);
      expect(expense.isApproved, isFalse);
      expect(expense.isPending, isFalse);
    });

    test('PaymentModel & PaymentReversalModel: Kalkulasi pembatalan dan sisa reversible', () {
      final paymentJson = {
        'id': 'pay-1',
        'amount': '200000.00',
        'postedBy': 'user-bendahara-1',
        'postedByName': 'Budi Bendahara',
        'postedAt': '2026-10-29T10:30:00Z',
        'notes': 'Transfer termin 1',
        'isReversed': false,
        'idempotencyKey': 'PAY-IDEM-001',
        'netAmount': 150000.0,
        'reversals': [
          {
            'id': 'rev-1',
            'amount': '50000.00',
            'reason': 'Koreksi salah transfer vendor',
            'reversedBy': 'user-bendahara-1',
            'reversedByName': 'Budi Bendahara',
            'reversedAt': '2026-10-29T11:00:00Z',
          }
        ],
      };

      final payment = PaymentModel.fromJson(paymentJson);

      expect(payment.id, 'pay-1');
      expect(payment.originalAmount, 200000.0);
      expect(payment.idempotencyKey, 'PAY-IDEM-001');
      expect(payment.reversals.length, 1);
      expect(payment.totalReversedAmount, 50000.0);
      expect(payment.remainingReversibleAmount, 150000.0);
      expect(payment.netAmount, 150000.0);

      final rev = payment.reversals.first;
      expect(rev.id, 'rev-1');
      expect(rev.amountValue, 50000.0);
      expect(rev.reason, 'Koreksi salah transfer vendor');
    });

    test('ExpenseRequestDetailModel: Parsing rincian lengkap & saldo sisa (remainingBalance)', () {
      final detailJson = {
        'request': {
          'id': 'exp-2',
          'eventId': 'ev-1',
          'title': 'Sewa Perlengkapan Acara',
          'requestedAmount': '500000.00',
          'approvedAmount': '500000.00',
          'status': 'partially_paid',
        },
        'payments': [
          {
            'id': 'pay-2',
            'amount': '300000.00',
            'postedBy': 'user-bendahara-1',
            'isReversed': false,
            'idempotencyKey': 'PAY-002',
            'netAmount': 300000.0,
            'reversals': [],
          }
        ],
        'summary': {
          'requestedAmount': 500000.0,
          'approvedAmount': 500000.0,
          'totalPaidNet': 300000.0,
          'remainingBalance': 200000.0,
          'isFullyPaid': false,
          'paymentCount': 1,
        },
      };

      final detail = ExpenseRequestDetailModel.fromJson(detailJson);

      expect(detail.request.id, 'exp-2');
      expect(detail.summary.approvedAmount, 500000.0);
      expect(detail.summary.totalPaidNet, 300000.0);
      expect(detail.summary.remainingBalance, 200000.0);
      expect(detail.summary.isFullyPaid, isFalse);
      expect(detail.summary.paymentCount, 1);
      expect(detail.payments.length, 1);
      expect(detail.payments.first.remainingReversibleAmount, 300000.0);
    });
  });

  group('Phase 6 Mobile - Pengujian Widget StatusBadge & Detail UI', () {
    testWidgets('StatusBadge menampilkan badge "Dibayar Sebagian" untuk partially_paid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'partially_paid'),
          ),
        ),
      );

      expect(find.text('Dibayar Sebagian'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    });

    testWidgets('StatusBadge menampilkan badge "Lunas" untuk paid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'paid'),
          ),
        ),
      );

      expect(find.text('Lunas'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });

    testWidgets('ExpenseDetailScreen: Menampilkan informasi pengeluaran dan ringkasan finansial', (tester) async {
      final mockExpense = ExpenseRequestModel(
        id: 'test-exp-01',
        eventId: 'test-ev-01',
        title: 'Spanduk & Banner Pentas',
        description: 'Pencetakan 3 spanduk 3x1m',
        requestedAmount: '450000',
        approvedAmount: '400000',
        status: 'approved',
        createdAt: '2026-10-29T10:00:00Z',
      );

      final mockOrg = OrganizationModel(
        id: 'org-01',
        name: 'OSIS SMKN 1',
        slug: 'osis-smkn1',
        role: 'panitia_anggota',
      );

      final mockDetail = ExpenseRequestDetailModel(
        request: mockExpense,
        payments: [],
        summary: ExpenseSummaryModel(
          requestedAmount: 450000,
          approvedAmount: 400000,
          totalPaidNet: 150000,
          remainingBalance: 250000,
          isFullyPaid: false,
          paymentCount: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseDetailScreen(
            expense: mockExpense,
            organization: mockOrg,
            initialDetail: mockDetail,
          ),
        ),
      );

      // Verifikasi judul dan deskripsi tampil
      expect(find.text('Spanduk & Banner Pentas'), findsOneWidget);
      expect(find.text('Pencetakan 3 spanduk 3x1m'), findsOneWidget);

      // Verifikasi status badge
      expect(find.text('Disetujui'), findsOneWidget);

      // Verifikasi ringkasan finansial
      expect(find.text('Nominal Diajukan'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(450000)), findsOneWidget);
      expect(find.text('Nominal Disetujui'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(400000)), findsOneWidget);
      expect(find.text('Total Dibayar (Net)'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(150000)), findsOneWidget);
      expect(find.text('Sisa Belum Dibayar'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(250000)), findsOneWidget);
    });

    testWidgets('ExpenseDetailScreen: Bendahara melihat tombol aksi untuk pengeluaran berstatus submitted', (tester) async {
      final pendingExpense = ExpenseRequestModel(
        id: 'test-exp-02',
        eventId: 'test-ev-01',
        title: 'Konsumsi Juri Lomba',
        requestedAmount: '200000',
        status: 'submitted',
        createdAt: '2026-10-29T10:00:00Z',
      );

      final bendaharaOrg = OrganizationModel(
        id: 'org-01',
        name: 'OSIS SMKN 1',
        slug: 'osis-smkn1',
        role: 'bendahara',
      );

      final pendingDetail = ExpenseRequestDetailModel(
        request: pendingExpense,
        payments: [],
        summary: ExpenseSummaryModel(
          requestedAmount: 200000,
          approvedAmount: 0,
          totalPaidNet: 0,
          remainingBalance: 0,
          isFullyPaid: false,
          paymentCount: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseDetailScreen(
            expense: pendingExpense,
            organization: bendaharaOrg,
            initialDetail: pendingDetail,
          ),
        ),
      );

      // Karena peran bendahara dan status submitted, tombol Setujui dan Tolak harus muncul
      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });
  });
}
