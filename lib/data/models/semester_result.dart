class SemesterResult {
  final int semester;
  final double sgpa;
  final double cgpa;
  final double creditsEarned;
  final List<CourseGrade> grades;
  final String? result;

  const SemesterResult({
    required this.semester,
    required this.sgpa,
    required this.cgpa,
    required this.creditsEarned,
    required this.grades,
    this.result,
  });
}

class CourseGrade {
  final String courseCode;
  final String courseName;
  final double credits;
  final String grade;
  final int gradePoint;

  const CourseGrade({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.grade,
    required this.gradePoint,
  });

  static int gradeToPoint(String grade) {
    switch (grade) {
      case 'O':
        return 10;
      case 'A+':
        return 9;
      case 'A':
        return 8;
      case 'B+':
        return 7;
      case 'B':
        return 6;
      case 'C':
        return 5;
      case 'P':
        return 0;
      default:
        return 0;
    }
  }
}
