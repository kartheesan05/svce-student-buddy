import 'models/course.dart';

class AppStateUtils {
  static String extractCode(String combined) {
    final parts = combined.split(' - ');
    return parts.isNotEmpty ? parts[0].trim() : combined;
  }

  static String extractName(String combined) {
    final idx = combined.indexOf(' - ');
    return idx >= 0 ? combined.substring(idx + 3).trim() : combined;
  }

  static String titleCase(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static CourseType inferCourseType(String name, String code, String? subId) {
    final lower = name.toLowerCase();
    if (subId == '2' || lower.contains('laboratory') || lower.contains('lab')) {
      return CourseType.lab;
    }
    if (code.startsWith('OE') ||
        code.startsWith('HS') ||
        code.startsWith('VD')) {
      return CourseType.elective;
    }
    return CourseType.theory;
  }

  static int dayNameToNumber(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 1;
    }
  }
}
