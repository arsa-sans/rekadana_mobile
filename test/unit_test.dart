import 'package:flutter_test/flutter_test.dart';
import 'package:rekadana_mobile/core/utils/currency_formatter.dart';
import 'package:rekadana_mobile/features/organization/models/organization_model.dart';
import 'package:rekadana_mobile/features/expenses/models/budget_item_model.dart';

void main() {
  group('Unit Test CurrencyFormatter', () {
    test('Format angka bulat Rupiah', () {
      expect(CurrencyFormatter.format(1000000), 'Rp1.000.000');
      expect(CurrencyFormatter.format('500000'), 'Rp500.000');
      expect(CurrencyFormatter.format(0), 'Rp0');
    });

    test('Clean to numeric string', () {
      expect(CurrencyFormatter.cleanToNumeric('Rp 1.500.000'), '1500000');
      expect(CurrencyFormatter.cleanToNumeric('123abc456'), '123456');
    });

    test('Parse to double', () {
      expect(CurrencyFormatter.parseToDouble('Rp 2.500.000'), 2500000.0);
    });
  });

  group('Unit Test OrganizationModel & BudgetItemModel', () {
    test('Peran role bendahara dan ketua', () {
      final orgBendahara = OrganizationModel(
        id: '1',
        name: 'Himpunan IF',
        slug: 'hima-if',
        role: 'bendahara',
      );
      expect(orgBendahara.isBendahara, isTrue);
      expect(orgBendahara.isKetua, isFalse);
      expect(orgBendahara.roleDisplayTitle, 'Bendahara');

      final orgKetua = OrganizationModel(
        id: '2',
        name: 'BEM',
        slug: 'bem',
        role: 'ketua_kegiatan',
      );
      expect(orgKetua.isKetua, isTrue);
      expect(orgKetua.roleDisplayTitle, 'Ketua Kegiatan');
    });

    test('Kalkulasi total estimasi item anggaran', () {
      final item = BudgetItemModel(
        id: 'item-1',
        name: 'Sewa Tenda',
        priority: 'required',
        estimatedUnitCost: '500000.00',
        quantity: '4',
      );
      expect(item.totalEstimatedCost, 2000000.0);
    });
  });
}
