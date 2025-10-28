/// BAWASA Billing Calculation Utility
/// Based on official BAWASA water bill form and payment scheme
class BillingCalculation {
  final double consumption10OrBelow;
  final double amount10OrBelow;
  final double amount10OrBelowWithDiscount;
  final double consumptionOver10;
  final double amountOver10;
  final double amountCurrentBilling;
  final int fiscalYear;

  BillingCalculation({
    required this.consumption10OrBelow,
    required this.amount10OrBelow,
    required this.amount10OrBelowWithDiscount,
    required this.consumptionOver10,
    required this.amountOver10,
    required this.amountCurrentBilling,
    required this.fiscalYear,
  });
}

class BAWASABillingCalculator {
  // BAWASA Pricing Structure (based on official form)
  static const double ratePerCubicMeter = 30.0; // 30 pesos per cubic meter

  // Progressive discount scheme (2022-2026)
  static const Map<int, double> discountScheme = {
    2022: 0.00, // 0% discount
    2023: 0.25, // 25% discount
    2024: 0.50, // 50% discount
    2025: 0.75, // 75% discount
    2026: 1.00, // 100% discount (FREE)
  };

  /// Calculate billing based on consumption and current fiscal year
  static BillingCalculation calculateBilling(
    double consumption, {
    int? fiscalYear,
  }) {
    final currentYear = fiscalYear ?? DateTime.now().year;
    final discountPercentage = getDiscountPercentage(currentYear);

    // Calculate consumption breakdown
    final consumption10OrBelow = consumption < 10 ? consumption : 10.0;
    final consumptionOver10 = consumption > 10 ? consumption - 10.0 : 0.0;

    // Calculate amounts without discount
    final amount10OrBelow = consumption10OrBelow * ratePerCubicMeter;

    // Apply discount for first 10 cubic meters
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
      fiscalYear: currentYear,
    );
  }

  /// Get discount percentage for a given fiscal year
  static double getDiscountPercentage(int year) {
    if (year < 2022) return 0.00;
    if (year >= 2027) return 1.00;
    return discountScheme[year] ?? 0.00;
  }

  /// Get expected payment for 10 cubic meters in a given year
  static double getExpectedPaymentFor10CuM({int? year}) {
    final currentYear = year ?? DateTime.now().year;
    final baseAmount = 10.0 * ratePerCubicMeter;
    final discountPercentage = getDiscountPercentage(currentYear);
    return baseAmount * (1 - discountPercentage);
  }
}
