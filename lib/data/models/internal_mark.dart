class InternalMark {
  final String courseName;
  final String courseCode;
  final bool isLab;
  final String cat1;
  final String cat2;
  final String cat3;
  final String asign1;
  final String asign2;
  final String asign3;
  final String modelExam;

  const InternalMark({
    required this.courseName,
    required this.courseCode,
    required this.isLab,
    required this.cat1,
    required this.cat2,
    required this.cat3,
    required this.asign1,
    required this.asign2,
    required this.asign3,
    required this.modelExam,
  });

  factory InternalMark.fromJson(Map<String, dynamic> json) {
    final subId = json['SubId'] as String? ?? '1';
    return InternalMark(
      courseName: (json['CourseName'] as String? ?? '').replaceAll('\u00a0', ' '),
      courseCode: json['CourseCode'] as String? ?? '',
      isLab: subId == '2',
      cat1: _clean(json['Cat1']),
      cat2: _clean(json['Cat2']),
      cat3: _clean(json['Cat3']),
      asign1: _clean(json['Asign1']),
      asign2: _clean(json['Asign2']),
      asign3: _clean(json['Asign3']),
      modelExam: _clean(json['ModelExam']),
    );
  }

  static String _clean(dynamic value) {
    if (value == null) return '-';
    final s = value.toString().trim();
    if (s.isEmpty || s == 'NA') return '-';
    return s;
  }
}
