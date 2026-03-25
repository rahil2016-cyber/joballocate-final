class Transaction {
  final String id;
  final String userId;
  final String type; // 'resume_creation' or 'job_application'
  final double amount; // in rupees
  final String description;
  final String status; // 'pending', 'completed', 'failed'
  final String? orderId; // for payment gateway
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    this.orderId,
    this.metadata,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      status: json['status'],
      orderId: json['order_id'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'status': status,
      'order_id': orderId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Pricing constants
const double RESUME_BUILD_COST = 20.0; // rupees
const double JOB_APPLICATION_COST = 100.0; // rupees
