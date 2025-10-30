/// BAWASA Billing Calculation Utility
/// Based on official BAWASA water bill form and payment scheme
class BillingCalculation {
  final double consumption10OrBelow;
  final double amount10OrBelow;
  final double amount10OrBelowWithDiscount;
  final double consumptionOver10;
  final double amountOver10;
  final double amountCurrentBilling;
  final int yearsOfService;

  BillingCalculation({
    required this.consumption10OrBelow,
    required this.amount10OrBelow,
    required this.amount10OrBelowWithDiscount,
    required this.consumptionOver10,
    required this.amountOver10,
    required this.amountCurrentBilling,
    required this.yearsOfService,
  });
}

class BAWASABillingCalculator {
  // BAWASA Pricing Structure (based on official form)
  static const double ratePerCubicMeter = 30.0; // 30 pesos per cubic meter

  /// Calculate billing based on consumption and years of service
  /// Years of service determines the discount percentage:
  /// - Year 1 (0-11 months): 0% discount
  /// - Year 2 (12-23 months): 25% discount
  /// - Year 3 (24-35 months): 50% discount
  /// - Year 4 (36-47 months): 75% discount
  /// - Year 5+ (48+ months): 100% discount (FREE)
  static BillingCalculation calculateBilling(
    double consumption, {
    required int yearsOfService,
  }) {
    final discountPercentage = getDiscountPercentage(yearsOfService);

    // Calculate consumption breakdown
    final consumption10OrBelow = consumption < 10 ? consumption : 10.0;
    final consumptionOver10 = consumption > 10 ? consumption - 10.0 : 0.0;

    // Calculate amounts without discount
    final amount10OrBelow = consumption10OrBelow * ratePerCubicMeter;

    // Apply discount for first 10 cubic meters ONLY
    final amount10OrBelowWithDiscount =
        amount10OrBelow * (1 - discountPercentage);

    // Amount for consumption over 10 cu.m (no discount)
    final amountOver10 = consumptionOver10 * ratePerCubicMeter;

    // Total current billing
    final amountCurrentBilling = amount10OrBelowWithDiscount + amountOver10;

    return BillingCalculation(
      consumption10OrBelow: consumption10OrBelow,
      amount10OrBelow: amount10OrBelow,
      amount10OrBelowWithDiscount: amount10OrBelowWithDiscount,
      consumptionOver10: consumptionOver10,
      amountOver10: amountOver10,
      amountCurrentBilling: amountCurrentBilling,
      yearsOfService: yearsOfService,
    );
  }

  /// Get discount percentage based on years of service
  /// - Year 1: 0% discount
  /// - Year 2: 25% discount
  /// - Year 3: 50% discount
  /// - Year 4: 75% discount
  /// - Year 5+: 100% discount (FREE)
  static double getDiscountPercentage(int yearsOfService) {
    if (yearsOfService < 1) {
      return 0.00; // 0% discount for less than 1 year
    } else if (yearsOfService == 1) {
      return 0.25; // 25% discount after 1 year
    } else if (yearsOfService == 2) {
      return 0.50; // 50% discount after 2 years
    } else if (yearsOfService == 3) {
      return 0.75; // 75% discount after 3 years
    } else {
      return 1.00; // 100% discount (FREE) after 4+ years
    }
  }

  /// Calculate years of service from account creation date
  static int calculateYearsOfService(DateTime accountCreationDate) {
    final now = DateTime.now();
    final difference = now.difference(accountCreationDate);
    final years = (difference.inDays / 365.25).floor();
    return years;
  }

  /// Get expected payment for 10 cubic meters based on years of service
  static double getExpectedPaymentFor10CuM({required int yearsOfService}) {
    final baseAmount = 10.0 * ratePerCubicMeter;
    final discountPercentage = getDiscountPercentage(yearsOfService);
    return baseAmount * (1 - discountPercentage);
  }
}
