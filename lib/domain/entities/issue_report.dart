import 'package:equatable/equatable.dart';

class IssueReport extends Equatable {
  final int? id;
  final String? issueType;
  final String? priority;
  final String? issueTitle;
  final String? description;
  final List<String>? issueImages;
  final DateTime? createdAt;
  final String? consumerId;

  const IssueReport({
    this.id,
    this.issueType,
    this.priority,
    this.issueTitle,
    this.description,
    this.issueImages,
    this.createdAt,
    this.consumerId,
  });

  factory IssueReport.fromJson(Map<String, dynamic> json) {
    return IssueReport(
      id: json['id'] as int?,
      issueType: json['issue_type'] as String?,
      priority: json['priority'] as String?,
      issueTitle: json['issue_title'] as String?,
      description: json['description'] as String?,
      issueImages: json['issue_images'] != null
          ? List<String>.from(json['issue_images'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      consumerId: json['consumer_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_type': issueType,
      'priority': priority,
      'issue_title': issueTitle,
      'description': description,
      'issue_images': issueImages,
      'created_at': createdAt?.toIso8601String(),
      'consumer_id': consumerId,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'issue_type': issueType,
      'priority': priority,
      'issue_title': issueTitle,
      'description': description,
      'issue_images': issueImages,
      'consumer_id': consumerId,
    };
  }

  IssueReport copyWith({
    int? id,
    String? issueType,
    String? priority,
    String? issueTitle,
    String? description,
    List<String>? issueImages,
    DateTime? createdAt,
    String? consumerId,
  }) {
    return IssueReport(
      id: id ?? this.id,
      issueType: issueType ?? this.issueType,
      priority: priority ?? this.priority,
      issueTitle: issueTitle ?? this.issueTitle,
      description: description ?? this.description,
      issueImages: issueImages ?? this.issueImages,
      createdAt: createdAt ?? this.createdAt,
      consumerId: consumerId ?? this.consumerId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    issueType,
    priority,
    issueTitle,
    description,
    issueImages,
    createdAt,
    consumerId,
  ];
}
