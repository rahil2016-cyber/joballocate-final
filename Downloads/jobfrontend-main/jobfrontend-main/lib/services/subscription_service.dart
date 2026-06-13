import 'package:joballocate/models/subscription.dart';
import 'api_service.dart';

class SubscriptionService {
  final ApiService _apiService = ApiService();

  // Unit prices (pay-per-use fallback)
  static const double RESUME_UNIT_PRICE = 20.0; // ₹20 per resume
  static const double JOB_UNIT_PRICE = 100.0;   // ₹100 per job apply

  /// Get all subscription plans. Falls back to hardcoded plans in demo mode.
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final raw = await _apiService.getSubscriptionPlans();
      if (raw.isEmpty) return kHardcodedPlans;
      return raw.map((j) => SubscriptionPlan.fromJson(j)).toList();
    } catch (_) {
      return kHardcodedPlans;
    }
  }

  /// Get plans filtered by category
  List<SubscriptionPlan> filterPlans(List<SubscriptionPlan> all, String type) {
    if (type == 'all') return all;
    return all.where((p) => p.type == type).toList();
  }

  /// Get user's active subscriptions
  Future<Map<String, dynamic>> getUserSubscriptions(
    String userId,
    String token,
  ) async {
    try {
      return await _apiService.getUserSubscriptions(userId, token);
    } catch (e) {
      throw Exception('Failed to load subscriptions: $e');
    }
  }

  /// Purchase a plan
  Future<Map<String, dynamic>> purchasePlan(
    String userId,
    String planId,
    String token,
  ) async {
    try {
      return await _apiService.purchaseSubscription(userId, planId, token);
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  /// Check if a plan is good value (savings from unit pricing)
  String getSavingsLabel(SubscriptionPlan plan) {
    double unitTotal = 0;
    if (plan.resumeCredits > 0 && plan.resumeCredits != 999) {
      unitTotal += plan.resumeCredits * RESUME_UNIT_PRICE;
    }
    if (plan.jobCredits > 0) {
      unitTotal += plan.jobCredits * JOB_UNIT_PRICE;
    }
    if (plan.resumeCredits == 999) {
      return 'Unlimited value';
    }
    if (unitTotal == 0) return '';
    final savings = unitTotal - plan.price;
    if (savings <= 0) return '';
    final pct = ((savings / unitTotal) * 100).round();
    return 'Save $pct% (₹${savings.toStringAsFixed(0)})';
  }
}
