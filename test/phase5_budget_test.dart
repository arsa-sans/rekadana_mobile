import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rekadana_mobile/core/utils/currency_formatter.dart';
import 'package:rekadana_mobile/core/widgets/confirmation_dialog.dart';
import 'package:rekadana_mobile/core/widgets/status_badge.dart';
import 'package:rekadana_mobile/features/organization/models/budget_version_model.dart';

void main() {
  group('Phase 5 Mobile - Pengujian Model Versi Anggaran & Approval', () {
    test('BudgetVersionModel.fromJson: Parsing atribut versi anggaran dan status booleans', () {
      final json = {
        'id': 'v-1',
        'eventId': 'ev-1',
        'versionNumber': 2,
        'status': 'submitted',
        'snapshotTotal': '4500000.00',
        'snapshotParticipantCount': 120,
        'snapshotAvailableFunds': '8000000.00',
        'submittedBy': 'user-ketua-1',
        'submittedByName': 'Ahmad Ketua',
        'submittedAt': '2026-10-28T08:00:00Z',
        'reviewedBy': null,
        'reviewedByName': null,
        'reviewedAt': null,
        'rejectionReason': null,
      };

      final version = BudgetVersionModel.fromJson(json);

      expect(version.id, 'v-1');
      expect(version.eventId, 'ev-1');
      expect(version.versionNumber, 2);
      expect(version.status, 'submitted');
      expect(version.snapshotTotal, 4500000.0);
      expect(version.snapshotParticipantCount, 120);
      expect(version.snapshotAvailableFunds, 8000000.0);
      expect(version.submittedBy, 'user-ketua-1');
      expect(version.submittedByName, 'Ahmad Ketua');
      expect(version.submittedAt, isNotNull);
      expect(version.isSubmitted, isTrue);
      expect(version.isApproved, isFalse);
      expect(version.isRejected, isFalse);
      expect(version.isDraft, isFalse);
      expect(version.statusLabel, 'Diajukan');
    });

    test('BudgetVersionModel: Status approved dan rejected terdeteksi dengan tepat', () {
      final jsonApproved = {
        'id': 'v-app',
        'eventId': 'ev-1',
        'versionNumber': 1,
        'status': 'approved',
        'snapshotTotal': '5000000.00',
        'snapshotParticipantCount': 100,
        'snapshotAvailableFunds': '6000000.00',
      };
      final vApproved = BudgetVersionModel.fromJson(jsonApproved);
      expect(vApproved.isApproved, isTrue);
      expect(vApproved.statusLabel, 'Disetujui');

      final jsonRejected = {
        'id': 'v-rej',
        'eventId': 'ev-1',
        'versionNumber': 2,
        'status': 'rejected',
        'snapshotTotal': '7000000.00',
        'snapshotParticipantCount': 100,
        'snapshotAvailableFunds': '6000000.00',
        'rejectionReason': 'Estimasi konsumsi melebihi anggaran yang disepakati',
      };
      final vRejected = BudgetVersionModel.fromJson(jsonRejected);
      expect(vRejected.isRejected, isTrue);
      expect(vRejected.statusLabel, 'Ditolak');
      expect(vRejected.rejectionReason, contains('melebihi anggaran'));
    });

    test('BudgetVersionDetailModel: Parsing item snapshot dan data perbandingan versi (diff snapshot)', () {
      final detailJson = {
        'version': {
          'id': 'v-2',
          'eventId': 'ev-1',
          'versionNumber': 2,
          'status': 'submitted',
          'snapshotTotal': '6500000.00',
          'snapshotParticipantCount': 150,
          'snapshotAvailableFunds': '10000000.00',
        },
        'items': [
          {
            'id': 'bi-1',
            'budgetVersionId': 'v-2',
            'name': 'Sewa Panggung',
            'category': 'Perlengkapan',
            'quantity': '1',
            'unitCost': '3500000.00',
            'total': '3500000.00',
          },
          {
            'id': 'bi-2',
            'budgetVersionId': 'v-2',
            'name': 'Konsumsi Peserta',
            'category': 'Konsumsi',
            'quantity': '150',
            'unitCost': '20000.00',
            'total': '3000000.00',
          },
        ],
        'comparison': {
          'previousVersionId': 'v-1',
          'previousVersionNumber': 1,
          'previousSnapshotTotal': '5000000.00',
          'previousParticipantCount': 100,
          'deltaTotal': '1500000.00',
          'deltaTotalPercentage': '30.00',
          'deltaParticipantCount': 50,
          'addedItemsCount': 1,
          'removedItemsCount': 0,
          'modifiedItemsCount': 1,
          'diffs': [
            {
              'name': 'Konsumsi Peserta',
              'category': 'Konsumsi',
              'type': 'modified',
              'oldQuantity': '100',
              'newQuantity': '150',
              'oldUnitCost': '15000.00',
              'newUnitCost': '20000.00',
              'oldTotal': '1500000.00',
              'newTotal': '3000000.00',
              'totalDifference': '1500000.00',
            },
          ],
        },
      };

      final detail = BudgetVersionDetailModel.fromJson(detailJson);

      expect(detail.version.versionNumber, 2);
      expect(detail.items.length, 2);
      expect(detail.items[0].name, 'Sewa Panggung');
      expect(detail.items[0].total, 3500000.0);

      expect(detail.comparison, isNotNull);
      final cmp = detail.comparison!;
      expect(cmp.previousVersionNumber, 1);
      expect(cmp.deltaTotal, 1500000.0);
      expect(cmp.deltaTotalPercentage, 30.0);
      expect(cmp.deltaParticipantCount, 50);
      expect(cmp.diffs.length, 1);
      expect(cmp.diffs.first.type, 'modified');
      expect(cmp.diffs.first.totalDifference, 1500000.0);
    });

    test('Pencegahan Self-Approval: Verifikasi logika segregasi tugas pemohon vs approver', () {
      const currentUserId = 'user-bendahara-a';

      // Kasus 1: Versi diajukan oleh Bendahara A sendiri -> dilarang self-approval
      final versionSubmittedBySelf = BudgetVersionModel(
        id: 'v-1',
        eventId: 'ev-1',
        versionNumber: 1,
        status: 'submitted',
        snapshotTotal: 5000000,
        snapshotParticipantCount: 50,
        snapshotAvailableFunds: 10000000,
        submittedBy: currentUserId,
      );
      final isSelfSubmission = versionSubmittedBySelf.submittedBy == currentUserId;
      expect(isSelfSubmission, isTrue, reason: 'Pemohon harus terdeteksi sebagai akun yang sama dengan current user');

      // Kasus 2: Versi diajukan oleh Ketua Kegiatan -> Bendahara A boleh mereview
      final versionSubmittedByKetua = BudgetVersionModel(
        id: 'v-2',
        eventId: 'ev-1',
        versionNumber: 2,
        status: 'submitted',
        snapshotTotal: 5000000,
        snapshotParticipantCount: 50,
        snapshotAvailableFunds: 10000000,
        submittedBy: 'user-ketua-b',
      );
      final canReviewOther = versionSubmittedByKetua.submittedBy != currentUserId;
      expect(canReviewOther, isTrue, reason: 'Pengajuan dari orang lain boleh direview oleh Bendahara');
    });
  });

  group('Phase 5 Mobile - Pengujian Widget & Dialog Interaktif', () {
    testWidgets('StatusBadge menampilkan teks dan warna yang benar untuk Draf, Diajukan, Disetujui, Ditolak', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'draft'),
                StatusBadge(status: 'submitted'),
                StatusBadge(status: 'approved'),
                StatusBadge(status: 'rejected'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Draf'), findsOneWidget);
      expect(find.text('Diajukan'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
    });

    testWidgets('ConfirmationDialog menampilkan pesan persetujuan anggaran dan merespons aksi konfirmasi', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    ctx,
                    title: 'Setujui Versi Anggaran #1',
                    message: 'Apakah Anda yakin ingin mengaktifkan anggaran sebesar ${CurrencyFormatter.format(5000000)}?',
                    confirmLabel: 'Setujui Anggaran',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui Versi Anggaran #1'), findsOneWidget);
      expect(find.textContaining('mengaktifkan anggaran sebesar Rp5.000.000'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Setujui Anggaran'), findsOneWidget);

      // Tekan tombol Setujui Anggaran
      await tester.tap(find.text('Setujui Anggaran'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('RejectionReasonDialog memvalidasi input alasan penolakan minimal 5 karakter', (tester) async {
      String? submittedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  submittedReason = await RejectionReasonDialog.show(
                    ctx,
                    title: 'Tolak Versi Anggaran #1',
                  );
                },
                child: const Text('Tolak Versi'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tolak Versi'));
      await tester.pumpAndSettle();

      expect(find.text('Tolak Versi Anggaran #1'), findsOneWidget);
      expect(find.text('Tolak Resmi'), findsOneWidget);

      // Tekan tombol Tolak Resmi saat input masih kosong -> validasi muncul
      await tester.tap(find.text('Tolak Resmi'));
      await tester.pumpAndSettle();

      expect(find.text('Alasan wajib diisi minimal 5 karakter.'), findsOneWidget);
      expect(submittedReason, isNull);

      // Isi alasan penolakan yang valid
      await tester.enterText(find.byType(TextFormField), 'Biaya sound system terlalu mahal');
      await tester.pumpAndSettle();

      // Submit kembali
      await tester.tap(find.text('Tolak Resmi'));
      await tester.pumpAndSettle();

      expect(submittedReason, 'Biaya sound system terlalu mahal');
    });
  });
}
