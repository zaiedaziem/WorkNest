import 'package:flutter_test/flutter_test.dart';
import 'package:worknest/models/claim_model.dart';

// Helper — build a minimal ClaimModel for testing getters
ClaimModel makeClaimModel({
  String claimType = 'travel',
  double amount = 100.0,
  double? suggestedAmount,
}) {
  return ClaimModel(
    id: 'test-id',
    employeeId: 'emp-1',
    companyId: 'co-1',
    claimType: claimType,
    title: 'Test Claim',
    claimDate: DateTime(2025, 6, 9),
    amount: amount,
    suggestedAmount: suggestedAmount,
    status: 'pending',
    createdAt: DateTime(2025, 6, 9),
  );
}

void main() {

  // ─────────────────────────────────────────────────────────────────────────
  // 1. ClaimPolicyRates.calculateMileage
  // Rate: RM 0.70/km for first 200 km, then RM 0.55/km above 200 km
  // ─────────────────────────────────────────────────────────────────────────
  group('ClaimPolicyRates.calculateMileage', () {

    test('0 km returns 0.0', () {
      expect(ClaimPolicyRates.calculateMileage(0), 0.0);
    });

    test('100 km → 100 × 0.70 = 70.0', () {
      expect(ClaimPolicyRates.calculateMileage(100), 70.0);
    });

    test('exactly 200 km → 200 × 0.70 = 140.0', () {
      expect(ClaimPolicyRates.calculateMileage(200), 140.0);
    });

    test('201 km → (200 × 0.70) + (1 × 0.55) = 140.55', () {
      expect(ClaimPolicyRates.calculateMileage(201), closeTo(140.55, 0.001));
    });

    test('300 km → (200 × 0.70) + (100 × 0.55) = 195.0', () {
      expect(ClaimPolicyRates.calculateMileage(300), closeTo(195.0, 0.001));
    });

    test('500 km → (200 × 0.70) + (300 × 0.55) = 305.0', () {
      expect(ClaimPolicyRates.calculateMileage(500), closeTo(305.0, 0.001));
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 2. ClaimPolicyRates.calculateAccommodation
  // Domestic only — overseas returns 0 (actual cost, paid separately)
  // Management with receipt: RM 300/night | without: RM 80/night
  // Staff     with receipt: RM 250/night | without: RM 60/night
  // ─────────────────────────────────────────────────────────────────────────
  group('ClaimPolicyRates.calculateAccommodation', () {

    test('overseas destination returns 0 (southeast_asia)', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'staff',
        hasReceipt: true,
        nights: 3,
        destination: 'southeast_asia',
      );
      expect(result, 0.0);
    });

    test('overseas destination returns 0 (other_foreign)', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'management',
        hasReceipt: true,
        nights: 2,
        destination: 'other_foreign',
      );
      expect(result, 0.0);
    });

    test('management with receipt: 2 nights → 2 × 300 = 600', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'management',
        hasReceipt: true,
        nights: 2,
        destination: 'domestic',
      );
      expect(result, 600.0);
    });

    test('management without receipt: 2 nights → 2 × 80 = 160', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'management',
        hasReceipt: false,
        nights: 2,
        destination: 'domestic',
      );
      expect(result, 160.0);
    });

    test('staff with receipt: 3 nights → 3 × 250 = 750', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'staff',
        hasReceipt: true,
        nights: 3,
        destination: 'domestic',
      );
      expect(result, 750.0);
    });

    test('staff without receipt: 3 nights → 3 × 60 = 180', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'staff',
        hasReceipt: false,
        nights: 3,
        destination: 'domestic',
      );
      expect(result, 180.0);
    });

    test('0 nights returns 0', () {
      final result = ClaimPolicyRates.calculateAccommodation(
        grade: 'staff',
        hasReceipt: true,
        nights: 0,
        destination: 'domestic',
      );
      expect(result, 0.0);
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 3. ClaimPolicyRates.calculateSubsistence
  // Management domestic: RM 100/day | SE Asia: RM 200 | Foreign: RM 300
  // Staff      domestic: RM 70/day  | SE Asia: RM 140 | Foreign: RM 210
  // No overnight stay → half rate (× 0.5)
  // ─────────────────────────────────────────────────────────────────────────
  group('ClaimPolicyRates.calculateSubsistence', () {

    test('management domestic overnight 2 days → 2 × 100 = 200', () {
      final result = ClaimPolicyRates.calculateSubsistence(
        grade: 'management',
        destination: 'domestic',
        fullDays: 2,
        isOvernightStay: true,
      );
      expect(result, 200.0);
    });

    test('management domestic no overnight → half rate: 1 × 100 × 0.5 = 50', () {
      final result = ClaimPolicyRates.calculateSubsistence(
        grade: 'management',
        destination: 'domestic',
        fullDays: 1,
        isOvernightStay: false,
      );
      expect(result, 50.0);
    });

    test('staff domestic overnight 3 days → 3 × 70 = 210', () {
      final result = ClaimPolicyRates.calculateSubsistence(
        grade: 'staff',
        destination: 'domestic',
        fullDays: 3,
        isOvernightStay: true,
      );
      expect(result, 210.0);
    });

    test('staff domestic no overnight → half rate: 1 × 70 × 0.5 = 35', () {
      final result = ClaimPolicyRates.calculateSubsistence(
        grade: 'staff',
        destination: 'domestic',
        fullDays: 1,
        isOvernightStay: false,
      );
      expect(result, 35.0);
    });

    test('management southeast_asia overnight 2 days → 2 × 200 = 400', () {
      final result = ClaimPolicyRates.calculateSubsistence(
        grade: 'management',
        destination: 'southeast_asia',
        fullDays: 2,
        isOvernightStay: true,
      );
      expect(result, 400.0);
    });

    test('staff other_foreign overnight 1 day → 1 × 210 = 210', () {
      final result = ClaimPolicyRates.calculateSubsistence(
        grade: 'staff',
        destination: 'other_foreign',
        fullDays: 1,
        isOvernightStay: true,
      );
      expect(result, 210.0);
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 4. ClaimModel.typeLabel
  // ─────────────────────────────────────────────────────────────────────────
  group('ClaimModel.typeLabel', () {

    test('"travel" → "Travel"', () {
      expect(makeClaimModel(claimType: 'travel').typeLabel, 'Travel');
    });

    test('"accommodation" → "Accommodation"', () {
      expect(makeClaimModel(claimType: 'accommodation').typeLabel, 'Accommodation');
    });

    test('"subsistence" → "Subsistence"', () {
      expect(makeClaimModel(claimType: 'subsistence').typeLabel, 'Subsistence');
    });

    test('"overseas" → "Overseas"', () {
      expect(makeClaimModel(claimType: 'overseas').typeLabel, 'Overseas');
    });

    test('unknown type → "Other"', () {
      expect(makeClaimModel(claimType: 'xyz').typeLabel, 'Other');
    });

  });


  // ─────────────────────────────────────────────────────────────────────────
  // 5. ClaimModel.exceedsPolicy
  // ─────────────────────────────────────────────────────────────────────────
  group('ClaimModel.exceedsPolicy', () {

    test('no suggestedAmount → never exceeds', () {
      final claim = makeClaimModel(amount: 999.0, suggestedAmount: null);
      expect(claim.exceedsPolicy, false);
    });

    test('amount < suggestedAmount → false', () {
      final claim = makeClaimModel(amount: 80.0, suggestedAmount: 100.0);
      expect(claim.exceedsPolicy, false);
    });

    test('amount == suggestedAmount → false', () {
      final claim = makeClaimModel(amount: 100.0, suggestedAmount: 100.0);
      expect(claim.exceedsPolicy, false);
    });

    test('amount > suggestedAmount → true', () {
      final claim = makeClaimModel(amount: 150.0, suggestedAmount: 100.0);
      expect(claim.exceedsPolicy, true);
    });

  });

}
