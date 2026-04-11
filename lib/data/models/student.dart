class Student {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String programme;
  final int currentSemester;
  final String enrollmentYear;
  final double cgpa;
  final int totalCreditsEarned;
  final String avatarUrl;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.programme,
    required this.currentSemester,
    required this.enrollmentYear,
    required this.cgpa,
    required this.totalCreditsEarned,
    this.avatarUrl = '',
  });
}
