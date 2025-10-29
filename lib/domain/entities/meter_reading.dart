class MeterReading {
  final String id;
  final String user_id_ref;
  final String meterType;
  final double readingValue;
  final DateTime readingDate;
  final String? notes;
  final String? photoUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final double consumption;

  MeterReading({
    required this.id,
    required this.user_id_ref,
    required this.meterType,
    required this.readingValue,
    required this.readingDate,
    this.notes,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedBy,
    this.confirmedAt,
    this.consumption = 0.0,
  });

  factory MeterReading.fromJson(Map<String, dynamic> json) {
    return MeterReading(
      id: json['id'] as String,
      user_id_ref:
          json['user_id_ref'] as String? ?? json['user_id'] as String? ?? '',
      meterType: json['meter_type'] as String,
      readingValue: (json['reading_value'] as num).toDouble(),
      readingDate: DateTime.parse(json['reading_date'] as String),
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      confirmedBy: json['confirmed_by'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      consumption: (json['consumption'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id_ref': user_id_ref,
      'meter_type': meterType,
      'reading_value': readingValue,
      'reading_date': readingDate.toIso8601String().split(
        'T',
      )[0], // YYYY-MM-DD format
      'notes': notes,
      'photo_url': photoUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'confirmed_by': confirmedBy,
      'confirmed_at': confirmedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'meter_type': meterType,
      'reading_value': readingValue,
      'reading_date': readingDate.toIso8601String().split(
        'T',
      )[0], // YYYY-MM-DD format
      'notes': notes,
      'photo_url': photoUrl,
      'status': status,
    };
  }

  MeterReading copyWith({
    String? id,
    String? user_id_ref,
    String? meterType,
    double? readingValue,
    DateTime? readingDate,
    String? notes,
    String? photoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? confirmedBy,
    DateTime? confirmedAt,
    double? consumption,
  }) {
    return MeterReading(
      id: id ?? this.id,
      user_id_ref: user_id_ref ?? this.user_id_ref,
      meterType: meterType ?? this.meterType,
      readingValue: readingValue ?? this.readingValue,
      readingDate: readingDate ?? this.readingDate,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      consumption: consumption ?? this.consumption,
    );
  }

  @override
  String toString() {
    return 'MeterReading(id: $id, user_id_ref: $user_id_ref, meterType: $meterType, readingValue: $readingValue, readingDate: $readingDate, notes: $notes, photoUrl: $photoUrl, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, confirmedBy: $confirmedBy, confirmedAt: $confirmedAt, consumption: $consumption)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterReading &&
        other.id == id &&
        other.user_id_ref == user_id_ref &&
        other.meterType == meterType &&
        other.readingValue == readingValue &&
        other.readingDate == readingDate &&
        other.notes == notes &&
        other.photoUrl == photoUrl &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.confirmedBy == confirmedBy &&
        other.confirmedAt == confirmedAt &&
        other.consumption == consumption;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      user_id_ref,
      meterType,
      readingValue,
      readingDate,
      notes,
      photoUrl,
      status,
      createdAt,
      updatedAt,
      confirmedBy,
      confirmedAt,
      consumption,
    );
  }
}
