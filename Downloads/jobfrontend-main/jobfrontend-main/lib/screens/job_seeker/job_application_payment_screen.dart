import 'package:flutter/material.dart';
import 'package:joballocate/models/job.dart';
import 'package:joballocate/services/payment_service.dart';

class JobApplicationPaymentScreen extends StatefulWidget {
  final Job job;
  final String userId;
  final String token;
  final String resumeId;

  const JobApplicationPaymentScreen({
    super.key,
    required this.job,
    required this.userId,
    required this.token,
    required this.resumeId,
  });

  @override
  State<JobApplicationPaymentScreen> createState() =>
      _JobApplicationPaymentScreenState();
}

class _JobApplicationPaymentScreenState extends State<JobApplicationPaymentScreen> {
  late final PaymentService _paymentService;
  bool _isLoading = false;
  double _walletBalance = 0;
  bool _hasEnoughBalance = false;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _checkBalance();
  }

  Future<void> _checkBalance() async {
    try {
      final balance = await _paymentService.getWalletBalance(widget.userId, widget.token);
      setState(() {
        _walletBalance = balance;
        _hasEnoughBalance = balance >= PaymentService.JOB_APPLICATION_COST;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking balance: $e')),
      );
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      // Initiate payment
      final paymentInfo = await _paymentService.initiateApplicationPayment(
        widget.userId,
        widget.job.id,
        widget.token,
      );

      // In a real scenario, you would integrate with a payment gateway here
      // For demo, we'll simulate payment completion
      await Future.delayed(const Duration(seconds: 2));

      // Apply for job
      final result = await _paymentService.applyForJob(
        userId: widget.userId,
        jobId: widget.job.id,
        resumeId: widget.resumeId,
        orderId: paymentInfo['order_id'],
        token: widget.token,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh balance
        await _checkBalance();

        // Navigate back after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Job details card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.companyName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.job.location,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.business_center, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.job.jobType,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Payment summary
          Card(
            elevation: 2,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentRow(
                    'Application Fee',
                    '₹${PaymentService.JOB_APPLICATION_COST.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 16),
                  _buildPaymentRow(
                    'Total Amount',
                    '₹${PaymentService.JOB_APPLICATION_COST.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Wallet balance
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Balance:'),
                      Text(
                        '₹${_walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _hasEnoughBalance ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_hasEnoughBalance)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Insufficient balance. Please add ₹${(PaymentService.JOB_APPLICATION_COST - _walletBalance).toStringAsFixed(2)} to your wallet.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          if (_hasEnoughBalance)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _processPayment,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _isLoading ? 'Processing...' : 'Confirm & Apply',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to wallet/add money screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redirecting to add money...')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Money to Wallet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade600,
              ),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          // Terms
          Center(
            child: Text(
              'By applying, you agree to our Terms & Conditions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 18 : 14,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }
}
