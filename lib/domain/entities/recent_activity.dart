import 'package:equatable/equatable.dart';

enum ActivityType {
  meterReading,
  billGenerated,
  billPaid,
  issueReported,
  issueResolved,
}

class RecentActivity extends Equatable {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? iconName;
  final Map<String, dynamic>? metadata;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.iconName,
    this.metadata,
  });

  factory RecentActivity.fromMeterReading(Map<String, dynamic> meterReading) {
    return RecentActivity(
      id: 'meter_reading_${meterReading['id']}',
      type: ActivityType.meterReading,
      title: 'Meter Reading Submitted',
      subtitle: 'Reading: ${meterReading['reading_value']} cubic meters',
      timestamp: DateTime.parse(meterReading['created_at']),
      iconName: 'speed',
      metadata: {
        'reading_value': meterReading['reading_value'],
        'meter_type': meterReading['meter_type'],
        'status': meterReading['status'],
      },
    );
  }

  factory RecentActivity.fromBilling(Map<String, dynamic> billing) {
    final paymentStatus = billing['payment_status'] as String;
    final isPaid = paymentStatus == 'paid';

    return RecentActivity(
      id: 'billing_${billing['id']}',
      type: isPaid ? ActivityType.billPaid : ActivityType.billGenerated,
      title: isPaid ? 'Bill Paid' : 'Bill Generated',
      subtitle: isPaid
          ? 'Amount: \$${billing['total_amount_due']}'
          : 'Amount: \$${billing['total_amount_due']}',
      timestamp: isPaid
          ? DateTime.parse(billing['payment_date'] ?? billing['created_at'])
          : DateTime.parse(billing['created_at']),
      iconName: 'receipt_long',
      metadata: {
        'total_amount_due': billing['total_amount_due'],
        'payment_status': paymentStatus,
        'billing_month': billing['billing_month'],
      },
    );
  }

  factory RecentActivity.fromIssueReport(Map<String, dynamic> issueReport) {
    return RecentActivity(
      id: 'issue_${issueReport['id']}',
      type: ActivityType.issueReported,
      title: 'Issue Reported',
      subtitle: issueReport['issue_title'] ?? 'Issue reported',
      timestamp: DateTime.parse(issueReport['created_at']),
      iconName: 'warning',
      metadata: {
        'issue_type': issueReport['issue_type'],
        'priority': issueReport['priority'],
        'issue_title': issueReport['issue_title'],
      },
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inSeconds > 10) {
      return '${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    subtitle,
    timestamp,
    iconName,
    metadata,
  ];
}
