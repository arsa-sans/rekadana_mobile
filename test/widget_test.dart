import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rekadana_mobile/core/widgets/app_button.dart';
import 'package:rekadana_mobile/core/widgets/currency_input_field.dart';
import 'package:rekadana_mobile/core/widgets/status_badge.dart';
import 'package:rekadana_mobile/features/auth/login_screen.dart';

void main() {
  testWidgets('Verifikasi tampilan halaman LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verifikasi identitas dan judul produk
    expect(find.text('RekaDana Mobile'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);
  });

  testWidgets('Verifikasi widget StatusBadge menampilkan teks dan ikon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge(status: 'approved'),
              StatusBadge(status: 'submitted'),
              StatusBadge(status: 'rejected'),
              StatusBadge(status: 'paid'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Diajukan'), findsOneWidget);
    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
  });

  testWidgets('Verifikasi widget CurrencyInputField format ribuan otomatis', (WidgetTester tester) async {
    String outputNumeric = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CurrencyInputField(
            label: 'Nominal Rupiah',
            onChanged: (val) {
              outputNumeric = val;
            },
          ),
        ),
      ),
    );

    expect(find.text('Nominal Rupiah'), findsOneWidget);
    expect(find.text('Rp'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '1500000');
    await tester.pump();

    expect(outputNumeric, '1500000');
    expect(find.text('1.500.000'), findsOneWidget);
  });

  testWidgets('Verifikasi target sentuh AppButton memenuhi standar minimal', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Uji Tombol',
            onPressed: () {},
          ),
        ),
      ),
    );

    final buttonFinder = find.byType(ElevatedButton);
    expect(buttonFinder, findsOneWidget);

    final Size buttonSize = tester.getSize(buttonFinder);
    // Verifikasi target sentuh minimal 44px (AppButton diatur 48px)
    expect(buttonSize.height >= 44.0, isTrue);
  });
}
