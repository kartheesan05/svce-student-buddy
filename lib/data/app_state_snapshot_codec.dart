import 'dart:convert';
import 'dart:typed_data';

import 'models/attendance_entry.dart';
import 'models/course.dart';
import 'models/internal_mark.dart';
import 'models/schedule_entry.dart';
import 'models/semester_result.dart';
import 'models/student.dart';

class AppStateSnapshotCodec {
  static Map<String, dynamic>? studentToJson(Student? value) {
    if (value == null) return null;
    return {
      'id': value.id,
      'name': value.name,
      'email': value.email,
      'phone': value.phone,
      'department': value.department,
      'programme': value.programme,
      'currentSemester': value.currentSemester,
      'enrollmentYear': value.enrollmentYear,
      'cgpa': value.cgpa,
      'totalCreditsEarned': value.totalCreditsEarned,
      'avatarUrl': value.avatarUrl,
      'photoBase64': value.photoBytes == null ? null : base64Encode(value.photoBytes!),
      'enrollmentNo': value.enrollmentNo,
      'degree': value.degree,
      'fatherName': value.fatherName,
      'motherName': value.motherName,
      'gender': value.gender,
      'dob': value.dob,
      'bloodGroup': value.bloodGroup,
      'category': value.category,
      'address': value.address,
      'city': value.city,
      'state': value.state,
      'postalCode': value.postalCode,
      'transportRoute': value.transportRoute,
      'boardingPoint': value.boardingPoint,
    };
  }

  static Student? studentFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final department = json['department'] as String?;
    final programme = json['programme'] as String?;
    final currentSemester = (json['currentSemester'] as num?)?.toInt();
    if (id == null ||
        name == null ||
        department == null ||
        programme == null ||
        currentSemester == null) {
      return null;
    }

    Uint8List? photoBytes;
    final photoBase64 = json['photoBase64'] as String?;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        photoBytes = base64Decode(photoBase64);
      } catch (_) {}
    }

    return Student(
      id: id,
      name: name,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      department: department,
      programme: programme,
      currentSemester: currentSemester,
      enrollmentYear: json['enrollmentYear'] as String?,
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      totalCreditsEarned: (json['totalCreditsEarned'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      photoBytes: photoBytes,
      enrollmentNo: json['enrollmentNo'] as String?,
      degree: json['degree'] as String?,
      fatherName: json['fatherName'] as String?,
      motherName: json['motherName'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      category: json['category'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      transportRoute: json['transportRoute'] as String?,
      boardingPoint: json['boardingPoint'] as String?,
    );
  }

  static Map<String, dynamic> courseToJson(Course value) {
    return {
      'code': value.code,
      'name': value.name,
      'instructor': value.instructor,
      'credits': value.credits,
      'totalClasses': value.totalClasses,
      'attendedClasses': value.attendedClasses,
      'room': value.room,
      'type': value.type.name,
      'courseNo': value.courseNo,
    };
  }

  static Course courseFromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? CourseType.theory.name;
    final parsedType = CourseType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => CourseType.theory,
    );
    return Course(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      instructor: json['instructor'] as String? ?? '-',
      credits: (json['credits'] as num?)?.toInt(),
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      attendedClasses: (json['attendedClasses'] as num?)?.toInt() ?? 0,
      room: json['room'] as String?,
      type: parsedType,
      courseNo: json['courseNo'] as String?,
    );
  }

  static Map<String, dynamic> scheduleEntryToJson(ScheduleEntry value) {
    return {
      'courseCode': value.courseCode,
      'courseName': value.courseName,
      'instructor': value.instructor,
      'room': value.room,
      'startTime': value.startTime,
      'endTime': value.endTime,
      'dayOfWeek': value.dayOfWeek,
    };
  }

  static ScheduleEntry scheduleEntryFromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      courseCode: json['courseCode'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      instructor: json['instructor'] as String? ?? '',
      room: json['room'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
    );
  }

  static Map<String, dynamic> semesterResultToJson(SemesterResult value) {
    return {
      'semester': value.semester,
      'sgpa': value.sgpa,
      'cgpa': value.cgpa,
      'creditsEarned': value.creditsEarned,
      'result': value.result,
      'grades': value.grades
          .map(
            (grade) => {
              'courseCode': grade.courseCode,
              'courseName': grade.courseName,
              'credits': grade.credits,
              'grade': grade.grade,
              'gradePoint': grade.gradePoint,
            },
          )
          .toList(),
    };
  }

  static SemesterResult semesterResultFromJson(Map<String, dynamic> json) {
    final grades = (json['grades'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (grade) => CourseGrade(
            courseCode: grade['courseCode'] as String? ?? '',
            courseName: grade['courseName'] as String? ?? '',
            credits: (grade['credits'] as num?)?.toDouble() ?? 0,
            grade: grade['grade'] as String? ?? '',
            gradePoint: (grade['gradePoint'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    return SemesterResult(
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0,
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0,
      creditsEarned: (json['creditsEarned'] as num?)?.toDouble() ?? 0,
      grades: grades,
      result: json['result'] as String?,
    );
  }

  static Map<String, dynamic> internalMarkToJson(InternalMark value) {
    return {
      'courseName': value.courseName,
      'courseCode': value.courseCode,
      'isLab': value.isLab,
      'cat1': value.cat1,
      'cat2': value.cat2,
      'cat3': value.cat3,
      'asign1': value.asign1,
      'asign2': value.asign2,
      'asign3': value.asign3,
      'modelExam': value.modelExam,
    };
  }

  static InternalMark internalMarkFromJson(Map<String, dynamic> json) {
    return InternalMark(
      courseName: json['courseName'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      isLab: json['isLab'] as bool? ?? false,
      cat1: json['cat1'] as String? ?? '-',
      cat2: json['cat2'] as String? ?? '-',
      cat3: json['cat3'] as String? ?? '-',
      asign1: json['asign1'] as String? ?? '-',
      asign2: json['asign2'] as String? ?? '-',
      asign3: json['asign3'] as String? ?? '-',
      modelExam: json['modelExam'] as String? ?? '-',
    );
  }

  static Map<String, dynamic> attendanceEntryToJson(AttendanceEntry entry) {
    return {
      'dateMs': entry.date.millisecondsSinceEpoch,
      'period': entry.period,
      'status': entry.status.name,
    };
  }

  static AttendanceEntry attendanceEntryFromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? AttendanceStatus.present.name;
    final status = AttendanceStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => AttendanceStatus.present,
    );
    return AttendanceEntry(
      date: DateTime.fromMillisecondsSinceEpoch(
        (json['dateMs'] as num?)?.toInt() ?? 0,
      ),
      period: json['period'] as String? ?? '',
      status: status,
    );
  }
}
