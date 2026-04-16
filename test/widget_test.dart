import 'package:flutter_test/flutter_test.dart';
import 'package:essence_plus/models/fuel_balance.dart';
import 'package:essence_plus/models/voucher.dart';
import 'package:essence_plus/core/constants/game_config.dart';

void main() {
  group('FuelBalance', () {
    test('fillPercentage calculates correctly', () {
      final balance = FuelBalance(
        userId: 'test',
        currentFuel: 500,
        tankCapacity: 1000,
        lastUpdated: DateTime.now(),
      );
      expect(balance.fillPercentage, 0.5);
    });

    test('isTankFull returns true when full', () {
      final balance = FuelBalance(
        userId: 'test',
        currentFuel: 1000,
        tankCapacity: 1000,
        lastUpdated: DateTime.now(),
      );
      expect(balance.isTankFull, true);
    });

    test('isTankFull returns false when not full', () {
      final balance = FuelBalance(
        userId: 'test',
        currentFuel: 999,
        tankCapacity: 1000,
        lastUpdated: DateTime.now(),
      );
      expect(balance.isTankFull, false);
    });
  });

  group('Voucher', () {
    test('isExpired returns true for past date', () {
      final voucher = Voucher(
        id: 'test',
        code: 'ABC123',
        valueAmount: 50,
        stationPartner: 'Shell',
        status: VoucherStatus.claimed,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(voucher.isExpired, true);
      expect(voucher.canBeRedeemed, false);
    });

    test('canBeRedeemed returns true for valid claimed voucher', () {
      final voucher = Voucher(
        id: 'test',
        code: 'ABC123',
        valueAmount: 50,
        stationPartner: 'Shell',
        status: VoucherStatus.claimed,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(voucher.canBeRedeemed, true);
    });

    test('displayValue formats correctly', () {
      final voucher = Voucher(
        id: 'test',
        code: 'ABC123',
        valueAmount: 50,
        stationPartner: 'Shell',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(voucher.displayValue, '50 MAD');
    });
  });

  group('GameConfig', () {
    test('tank capacity is set', () {
      expect(GameConfig.tankCapacity, 1000);
    });

    test('speed limits are valid', () {
      expect(GameConfig.maxSpeed, greaterThan(GameConfig.initialSpeed));
    });

    test('hazard category weights sum to a positive value', () {
      final total = GameConfig.weightCivilian +
          GameConfig.weightNatural +
          GameConfig.weightPolitical;
      expect(total, greaterThan(0));
    });

    test('platform bonus is much larger than a regular barrel drop', () {
      expect(
        GameConfig.platformBonusBarrels,
        greaterThan(GameConfig.barrelsPerDrop * 5),
      );
    });
  });
}
