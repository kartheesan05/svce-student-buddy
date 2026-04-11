class SemesterResult {
  final int semester;
  final double sgpa;
  final double cgpa;
  final int creditsEarned;
  final List<CourseGrade> grades;

  const SemesterResult({
    required this.semester,
    required this.sgpa,
    required this.cgpa,
    required this.creditsEarned,
    required this.grades,
  });
}

class CourseGrade {
  final String courseCode;
  final String courseName;
  final int credits;
  final String grade;
  final int gradePoint;

  const CourseGrade({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.grade,
    required this.gradePoint,
  });
}
