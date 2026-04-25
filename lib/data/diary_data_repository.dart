import 'api_service.dart';
import 'app_state_utils.dart';
import 'models/attendance_entry.dart';
import 'models/course.dart';
import 'models/internal_mark.dart';
import 'models/schedule_entry.dart';
import 'models/semester_result.dart';
import 'models/student.dart';
import 'prefs_service.dart';

class DiaryHomeData {
  final Student student;
  final List<Course> courses;
  final List<ScheduleEntry> schedule;
  final List<InternalMark> internalMarks;

  const DiaryHomeData({
    required this.student,
    required this.courses,
    required this.schedule,
    required this.internalMarks,
  });
}

class SessionInfo {
  final int sessionNo;
  final int semesterNo;

  const SessionInfo({required this.sessionNo, required this.semesterNo});
}

class DiaryDataRepository {
  DiaryDataRepository({required this.api, required this.prefs});

  final ApiService api;
  final PrefsService prefs;

  Map<String, dynamic>? _loginData;
  List<SessionInfo> _externalSessions = const [];

  void applyLoginData(Map<String, dynamic> data) {
    _loginData = data;
    api.applyLoginResponse(data);
    _externalSessions = _parseExternalSessions(data);
  }

  void clearSession() {
    _loginData = null;
    _externalSessions = const [];
  }

  Future<DiaryHomeData> getHomeData() async {
    return _withSessionRefreshRetry(() async {
      final loginData = _loginData;
      if (loginData == null) {
        throw ApiException('No active session found. Please login again.');
      }
      final baseStudent = _studentFromLoginData(loginData);

      final profileFuture = api.getProfile();
      final attendanceFuture = api.getAttendance();
      final scheduleFuture = api.getSchedule();
      final internalFuture = _getInternalMarksForCurrentSession();

      final profileData = await profileFuture;
      final attendanceData = await attendanceFuture;
      final scheduleData = await scheduleFuture;
      final internalMarks = await internalFuture;

      final mergedStudent = Student.fromProfileResponse(
        profileData,
        base: baseStudent,
      );

      final courses = _coursesFromAttendance(
        attendanceData,
        loginData['StudentCourse'] as List<dynamic>? ?? const [],
      );
      final schedule = _scheduleFromApi(scheduleData);

      final latestResult = await _getLatestSemesterResult();
      final studentWithCgpa = latestResult == null
          ? mergedStudent
          : mergedStudent.copyWith(
              cgpa: latestResult.result.cgpa,
              totalCreditsEarned: latestResult.cumulativeCredits,
            );

      return DiaryHomeData(
        student: studentWithCgpa,
        courses: courses,
        schedule: schedule,
        internalMarks: internalMarks,
      );
    });
  }

  Future<List<AttendanceEntry>> getAttendanceBySubject(String courseNo) async {
    return _withSessionRefreshRetry(() async {
      final data = await api.getAttendanceBySubject(courseNo);
      final list = data['AttendanceBySubject'] as List<dynamic>? ?? const [];
      final entries = list
          .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return entries;
    });
  }

  Future<List<SemesterResult>> getSemResults() async {
    return _withSessionRefreshRetry(() async {
      if (_externalSessions.isEmpty) {
        return const <SemesterResult>[];
      }

      final outcomes = await Future.wait(
        _externalSessions.map((session) async {
          final data = await api.getExternalResults(
            session.sessionNo,
            session.semesterNo,
          );
          return _semesterResultFromApiData(data, session);
        }),
      );

      return outcomes
          .whereType<_ParsedSemesterResult>()
          .map((parsed) => parsed.result)
          .toList();
    });
  }

  Future<List<InternalMark>> _getInternalMarksForCurrentSession() async {
    final session = api.sessionNo;
    final semester = api.semesterNo;
    if (session == null || semester == null) return const <InternalMark>[];

    final data = await api.getInternalMarks(session, semester);
    final marks = data['InternalMarks'] as List<dynamic>? ?? const [];
    return marks
        .map((m) => InternalMark.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<_ParsedSemesterResult?> _getLatestSemesterResult() async {
    if (_externalSessions.isEmpty) return null;
    final latest = _externalSessions.last;
    final data = await api.getExternalResults(latest.sessionNo, latest.semesterNo);
    return _semesterResultFromApiData(data, latest);
  }

  Future<T> _withSessionRefreshRetry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      if (!_isSessionExpiredError(e)) rethrow;
      final refreshed = await _refreshSession();
      if (!refreshed) {
        throw ApiException(
          'Session expired, cannot refresh. Please logout and login again.',
        );
      }
      return request();
    }
  }

  bool _isSessionExpiredError(ApiException error) {
    final message = error.message.toLowerCase();
    return message.contains('session expired') ||
        message.contains('please sign in again') ||
        message.contains('please login again');
  }

  Future<bool> _refreshSession() async {
    final savedUsername = await prefs.getSavedUsername();
    final savedPassword = await prefs.getSavedPassword();
    if (savedUsername == null ||
        savedUsername.trim().isEmpty ||
        savedPassword == null ||
        savedPassword.isEmpty) {
      return false;
    }

    try {
      final refreshedLogin = await api.login(
        _normalizeUsername(savedUsername),
        savedPassword,
      );
      applyLoginData(refreshedLogin);
      await prefs.savePersistedSession(refreshedLogin);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _normalizeUsername(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'@svce\.ac\.in$', caseSensitive: false), '')
        .trim();
  }

  Student _studentFromLoginData(Map<String, dynamic> data) {
    final userInfo = data['UserInfo'] as Map<String, dynamic>? ?? const {};
    return Student(
      id: userInfo['RegNo'] as String? ?? '',
      name: AppStateUtils.titleCase(userInfo['UserName'] as String? ?? ''),
      department: userInfo['BranchName'] as String? ?? '',
      programme: userInfo['DegreeName'] as String? ?? '',
      currentSemester: int.tryParse(userInfo['SemesterNo']?.toString() ?? '') ?? 0,
    );
  }

  List<SessionInfo> _parseExternalSessions(Map<String, dynamic> data) {
    final extSessions = data['ExternalSession'] as List<dynamic>? ?? const [];
    final sessions = extSessions
        .map(
          (s) => SessionInfo(
            sessionNo: int.tryParse(s['SessionNo']?.toString() ?? '') ?? 0,
            semesterNo: int.tryParse(s['SemesterNo']?.toString() ?? '') ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.semesterNo.compareTo(b.semesterNo));
    return sessions;
  }

  List<Course> _coursesFromAttendance(
    Map<String, dynamic> attendanceData,
    List<dynamic> studentCourses,
  ) {
    final details = attendanceData['AttendanceDetails'] as List<dynamic>? ?? const [];

    final courseMap = <String, Map<String, dynamic>>{};
    for (final sc in studentCourses) {
      final no = sc['CourseNo'] as String? ?? '';
      courseMap[no] = sc as Map<String, dynamic>;
    }

    return details.map((att) {
      final a = att as Map<String, dynamic>;
      final courseNo = a['CourseNo'] as String? ?? '';
      final sc = courseMap[courseNo];

      final courseCode = sc?['CourseCode'] as String? ??
          AppStateUtils.extractCode(a['Course_Name'] as String? ?? '');
      final courseName = sc?['CourseName'] as String? ??
          AppStateUtils.extractName(a['Course_Name'] as String? ?? '');

      final type = AppStateUtils.inferCourseType(
        courseName,
        courseCode,
        sc?['SubId'] as String?,
      );

      return Course(
        code: courseCode,
        name: courseName,
        instructor: AppStateUtils.titleCase(a['UaName'] as String? ?? '-'),
        totalClasses: (a['Total_Class'] as num?)?.toInt() ?? 0,
        attendedClasses: (a['Present'] as num?)?.toInt() ?? 0,
        type: type,
        courseNo: courseNo,
      );
    }).toList();
  }

  List<ScheduleEntry> _scheduleFromApi(Map<String, dynamic> data) {
    final tables = data['ClassTables'] as List<dynamic>?;
    if (tables == null) return const <ScheduleEntry>[];

    final entries = <ScheduleEntry>[];
    for (final day in tables) {
      final d = day as Map<String, dynamic>;
      final dayName = d['Day'] as String? ?? '';
      final dayOfWeek = AppStateUtils.dayNameToNumber(dayName);
      final details = d['Detail'] as List<dynamic>? ?? const [];

      for (final lecture in details) {
        final l = lecture as Map<String, dynamic>;
        final lectureTime = l['LectureTime'] as String? ?? '';

        String courseName = '';
        String courseCode = '';
        String section = '';
        final detailList = l['DetailList'] as List<dynamic>?;
        if (detailList != null && detailList.isNotEmpty) {
          final inner = detailList.first as List<dynamic>?;
          if (inner != null) {
            for (final kv in inner) {
              final m = kv as Map<String, dynamic>;
              final key = m['Key'] as String? ?? '';
              final value = m['Value'] as String? ?? '';
              if (key == 'Course Name') courseName = value;
              if (key == 'Course Code') courseCode = value;
              if (key == 'Section') section = value;
            }
          }
        }

        if (courseName.isEmpty || courseName == '-') continue;

        final timeMatch =
            RegExp(r'(.+\s*[AP]M)\s*-\s*(.+\s*[AP]M)').firstMatch(lectureTime);
        final startTime = timeMatch?.group(1)?.trim() ?? '';
        final endTime = timeMatch?.group(2)?.trim() ?? '';

        entries.add(
          ScheduleEntry(
            courseCode: courseCode,
            courseName: courseName,
            instructor: '',
            room: section.isNotEmpty ? 'Sec $section' : '',
            startTime: startTime,
            endTime: endTime,
            dayOfWeek: dayOfWeek,
          ),
        );
      }
    }

    return _mergeConsecutiveEntries(entries);
  }

  List<ScheduleEntry> _mergeConsecutiveEntries(List<ScheduleEntry> entries) {
    if (entries.isEmpty) return entries;

    final byDay = <int, List<ScheduleEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.dayOfWeek, () => []).add(e);
    }

    final merged = <ScheduleEntry>[];
    for (final dayEntries in byDay.values) {
      ScheduleEntry? current;
      for (final entry in dayEntries) {
        if (current != null && current.courseCode == entry.courseCode) {
          current = ScheduleEntry(
            courseCode: current.courseCode,
            courseName: current.courseName,
            instructor: current.instructor,
            room: current.room,
            startTime: current.startTime,
            endTime: entry.endTime,
            dayOfWeek: current.dayOfWeek,
          );
        } else {
          if (current != null) merged.add(current);
          current = entry;
        }
      }
      if (current != null) merged.add(current);
    }
    return merged;
  }

  _ParsedSemesterResult? _semesterResultFromApiData(
    Map<String, dynamic> data,
    SessionInfo session,
  ) {
    try {
      final marks = data['ExternalMarks'] as List<dynamic>? ?? const [];
      final resultInfo = data['Result'] as List<dynamic>? ?? const [];
      final extResult = data['extStudentResult'] as Map<String, dynamic>? ?? const {};

      double sgpa = 0;
      double cgpa = 0;
      double semCredits = 0;

      for (final r in resultInfo) {
        final m = r as Map<String, dynamic>;
        final key = m['Key'] as String? ?? '';
        final value = double.tryParse(m['Value']?.toString() ?? '') ?? 0;
        if (key == 'SGPA') sgpa = value;
        if (key == 'CGPA') cgpa = value;
      }
      if (sgpa == 0) {
        sgpa = double.tryParse(extResult['SGPA']?.toString() ?? '') ?? 0;
      }
      if (cgpa == 0) {
        cgpa = double.tryParse(extResult['CGPA']?.toString() ?? '') ?? 0;
      }

      final grades = <CourseGrade>[];
      for (final mark in marks) {
        final m = mark as Map<String, dynamic>;
        final credit = double.tryParse(m['Credits']?.toString() ?? '') ?? 0;
        final grade = m['Grade'] as String? ?? '';
        semCredits += credit;
        grades.add(
          CourseGrade(
            courseCode: m['CourseCode'] as String? ?? '',
            courseName: (m['CourseName'] as String? ?? '').replaceAll('\u00a0', ' '),
            credits: credit,
            grade: grade,
            gradePoint: CourseGrade.gradeToPoint(grade),
          ),
        );
      }

      final cumulativeCredits =
          double.tryParse(extResult['CUMMULATIVE_CREDITS']?.toString() ?? '')
              ?.toInt();

      return _ParsedSemesterResult(
        result: SemesterResult(
          semester: session.semesterNo,
          sgpa: sgpa,
          cgpa: cgpa,
          creditsEarned: semCredits,
          grades: grades,
          result: extResult['PASSFAIL'] as String?,
        ),
        cumulativeCredits: cumulativeCredits,
      );
    } catch (_) {
      return null;
    }
  }
}

class _ParsedSemesterResult {
  final SemesterResult result;
  final int? cumulativeCredits;

  const _ParsedSemesterResult({
    required this.result,
    required this.cumulativeCredits,
  });
}
