class ScheduleEntry {
  final String courseCode;
  final String courseName;
  final String instructor;
  final String room;
  final String startTime;
  final String endTime;
  final int dayOfWeek; // 1=Monday ... 5=Friday

  const ScheduleEntry({
    required this.courseCode,
    required this.courseName,
    required this.instructor,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
  });

  String get timeSlot => '$startTime – $endTime';
}
