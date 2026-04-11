import 'package:intl/intl.dart';

class AttendanceEntry {
  final DateTime date;
  final AttendanceStatus status;
  final String period;

  const AttendanceEntry({
    required this.date,
    required this.status,
    required this.period,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    final dateStr = json['AttDate'] as String? ?? '';
    final statusStr = json['AttStatus'] as String? ?? '';

    DateTime date;
    try {
      date = DateFormat('dd-MM-yyyy').parse(dateStr);
    } catch (_) {
      date = DateTime(2000);
    }

    final AttendanceStatus status;
    switch (statusStr) {
      case '1':
        status = AttendanceStatus.present;
      case '2':
        status = AttendanceStatus.onDuty;
      default:
        status = AttendanceStatus.absent;
    }

    return AttendanceEntry(
      date: date,
      status: status,
      period: json['Period'] as String? ?? '',
    );
  }
}

enum AttendanceStatus { present, absent, onDuty }
