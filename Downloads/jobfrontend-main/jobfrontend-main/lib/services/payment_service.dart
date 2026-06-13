import 'package:joballocate/models/transaction.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  static const double RESUME_CREATE_COST = 20.0; // rupees
  static const double JOB_APPLICATION_COST = 100.0; // rupees

  /// Get user's wallet balance
  Future<double> getWalletBalance(String userId, String token) async {
    try {
      return await _apiService.getWalletBalance(userId, token);
    } catch (e) {
      throw Exception('Failed to get wallet balance: $e');
    }
  }

  /// Check if user has enough balance for resume creation
  Future<bool> canCreateResume(String userId, String token) async {
    try {
      final balance = await getWalletBalance(userId, token);
      return balance >= RESUME_CREATE_COST;
    } catch (e) {
      throw Exception('Error checking balance: $e');
    }
  }

  /// Check if user has enough balance for job application
  Future<bool> canApplyForJob(String userId, String token) async {
    try {
      final balance = await getWalletBalance(userId, token);
      return balance >= JOB_APPLICATION_COST;
    } catch (e) {
      throw Exception('Error checking balance: $e');
    }
  }

  /// Initiate payment for resume creation
  /// Amount: 20 rupees
  Future<Map<String, dynamic>> initiateResumePayment(
    String userId,
    String token,
  ) async {
    try {
      final result = await _apiService.initiateResumePayment(userId, token);
      return result;
    } catch (e) {
      throw Exception('Failed to initiate resume payment: $e');
    }
  }

  /// Initiate payment for job application
  /// Amount: 100 rupees
  Future<Map<String, dynamic>> initiateApplicationPayment(
    String userId,
    String jobId,
    String token,
  ) async {
    try {
      final result = await _apiService.initiateApplicationPayment(
        userId,
        jobId,
        token,
      );
      return result;
    } catch (e) {
      throw Exception('Failed to initiate application payment: $e');
    }
  }

  /// Apply for a job (includes payment verification)
  /// Cost: 99 rupees
  Future<Map<String, dynamic>> applyForJob({
    required String userId,
    required String jobId,
    required String resumeId,
    required String orderId,
    required String token,
  }) async {
    try {
      final result = await _apiService.applyForJob(
        userId,
        jobId,
        resumeId,
        orderId,
        token,
      );
      return result;
    } catch (e) {
      throw Exception('Failed to apply for job: $e');
    }
  }

  /// Get transaction history
  Future<List<Transaction>> getTransactionHistory(
    String userId,
    String token,
  ) async {
    try {
      final transactions = await _apiService.getTransactionHistory(userId, token);
      return transactions
          .map((t) => Transaction.fromJson(t))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transaction history: $e');
    }
  }

  /// Get transaction count by type
  Future<int> getTransactionCount(
    String userId,
    String token,
    String type,
  ) async {
    try {
      final transactions = await getTransactionHistory(userId, token);
      return transactions.where((t) => t.type == type).length;
    } catch (e) {
      throw Exception('Error getting transaction count: $e');
    }
  }

  /// Get total spent on a specific transaction type
  Future<double> getTotalSpent(
    String userId,
    String token,
    String type,
  ) async {
    try {
      final transactions = await getTransactionHistory(userId, token);
      final filtered = transactions.where((t) => t.type == type).toList();
      double total = 0;
      for (var transaction in filtered) {
        if (transaction.status == 'completed') {
          total += transaction.amount;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Error calculating total spent: $e');
    }
  }
}
