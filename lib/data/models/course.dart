class Course {
  final String code;
  final String name;
  final String instructor;
  final int credits;
  final int totalClasses;
  final int attendedClasses;
  final String room;
  final CourseType type;

  const Course({
    required this.code,
    required this.name,
    required this.instructor,
    required this.credits,
    required this.totalClasses,
    required this.attendedClasses,
    required this.room,
    this.type = CourseType.theory,
  });

  double get attendancePercent =>
      totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

  bool get isAttendanceLow => attendancePercent < 75;
}

enum CourseType { theory, lab, elective }
