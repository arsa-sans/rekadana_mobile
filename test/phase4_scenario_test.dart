import 'package:flutter_test/flutter_test.dart';
import 'package:rekadana_mobile/core/utils/currency_formatter.dart';
import 'package:rekadana_mobile/features/scenarios/models/scenario_model.dart';

void main() {
  group('Phase 4 Mobile - Pengujian Scenario Lab & Kalkulasi Desimal', () {
    test('ScenarioItemModel.fromJson: Parsing atribut item kebutuhan dengan benar', () {
      final json = {
        'id': 'item-1',
        'name': 'Konsumsi Siang',
        'category': 'Konsumsi',
        'priority': 'required',
        'quantity': '50.00',
        'estimatedUnitCost': '25000.00',
        'itemTotal': '1250000.00',
        'isIncluded': true,
        'notes': 'Kotak makan siang menu standar',
      };

      final item = ScenarioItemModel.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.name, 'Konsumsi Siang');
      expect(item.category, 'Konsumsi');
      expect(item.priority, 'required');
      expect(item.quantity, 50.0);
      expect(item.estimatedUnitCost, 25000.0);
      expect(item.itemTotal, 1250000.0);
      expect(item.isIncluded, isTrue);
      expect(item.notes, 'Kotak makan siang menu standar');
    });

    test('ScenarioModel.fromJson: Parsing skenario standar dan kalkulasi per peserta', () {
      final json = {
        'id': 'sc-1',
        'name': 'Skenario Standar',
        'description': 'Simulasi biaya standar',
        'participantCount': 50,
        'availableFunds': '5000000.00',
        'scenarioTotal': '3500000.00',
        'costPerParticipant': '70000.00',
        'fundGap': '1500000.00',
        'isDeficit': false,
        'unfundedItemsCount': 0,
        'items': [
          {
            'id': 'it-1',
            'name': 'Sewa Sound',
            'quantity': '1',
            'estimatedUnitCost': '500000',
            'itemTotal': '500000',
            'isIncluded': true,
          }
        ],
      };

      final scenario = ScenarioModel.fromJson(json);

      expect(scenario.id, 'sc-1');
      expect(scenario.name, 'Skenario Standar');
      expect(scenario.description, 'Simulasi biaya standar');
      expect(scenario.participantCount, 50);
      expect(scenario.availableFunds, 5000000.0);
      expect(scenario.scenarioTotal, 3500000.0);
      expect(scenario.costPerParticipant, 70000.0);
      expect(scenario.fundGap, 1500000.0);
      expect(scenario.isDeficit, isFalse);
      expect(scenario.unfundedItemsCount, 0);
      expect(scenario.items.length, 1);
      expect(scenario.items.first.name, 'Sewa Sound');
    });

    test('Decimal Math Edge Case: Skenario dengan item 0 kuantitas dan 0 biaya', () {
      final json = {
        'id': 'sc-zero',
        'name': 'Skenario Zero',
        'description': null,
        'participantCount': 0,
        'availableFunds': '5000000.00',
        'scenarioTotal': '0.00',
        'costPerParticipant': null,
        'fundGap': '5000000.00',
        'isDeficit': false,
        'unfundedItemsCount': 0,
        'items': [],
      };

      final scenario = ScenarioModel.fromJson(json);

      expect(scenario.scenarioTotal, 0.0);
      expect(scenario.isDeficit, isFalse);
      expect(scenario.costPerParticipant, isNull);
      expect(scenario.fundGap, 5000000.0);
    });

    test('Defisit Detection: Skenario dengan total melebihi pagu ditandai isDeficit=true', () {
      final json = {
        'id': 'sc-deficit',
        'name': 'Skenario Mewah',
        'description': 'Melebihi pagu',
        'participantCount': 20,
        'availableFunds': '3000000.00',
        'scenarioTotal': '4500000.00',
        'costPerParticipant': '225000.00',
        'fundGap': '-1500000.00',
        'isDeficit': true,
        'unfundedItemsCount': 1,
        'items': [],
      };

      final scenario = ScenarioModel.fromJson(json);

      expect(scenario.isDeficit, isTrue);
      expect(scenario.fundGap, -1500000.0);
      expect(scenario.unfundedItemsCount, 1);
    });

    test('Currency Formatter: Format IDR rupiah Indonesia yang valid', () {
      expect(CurrencyFormatter.format(0), 'Rp0');
      expect(CurrencyFormatter.format(1250000), 'Rp1.250.000');
    });
  });
}
