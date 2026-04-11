import 'package:flutter/widgets.dart';
import 'api_service.dart';
import 'models/course.dart';
import 'models/internal_mark.dart';
import 'models/schedule_entry.dart';
import 'models/semester_result.dart';
import 'models/student.dart';
import 'prefs_service.dart';

String _userVisibleNetworkError(Object error) {
  final s = error.toString();
  if (s.contains('Failed host lookup') ||
      s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('Network is unreachable') ||
      s.contains('Connection timed out')) {
    return "Can't reach the server. Check your internet connection and try again.";
  }
  return s;
}

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();
  late final PrefsService prefs;

  Student? student;
  List<Course> courses = [];
  List<ScheduleEntry> schedule = [];
  List<SemesterResult> semesterResults = [];
  List<InternalMark> internalMarks = [];
  bool isInternalMarksLoading = false;

  bool isLoggedIn = false;
  bool isLoading = false;
  String? error;

  Map<String, dynamic>? _loginData;
  List<_SessionInfo> _externalSessions = [];

  Future<String?> login(String username, String password) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      _loginData = await api.login(username, password);
      isLoggedIn = true;
      _parseLoginData();
      await prefs.savePersistedSession(_loginData!);
      notifyListeners();

      _loadAllData();
      return null;
    } on ApiException catch (e) {
      error = e.message;
      isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      final message = _userVisibleNetworkError(e);
      error = message;
      isLoading = false;
      notifyListeners();
      return message;
    }
  }

  void _parseLoginData() {
    final data = _loginData!;
    final userInfo = data['UserInfo'] as Map<String, dynamic>;

    student = Student(
      id: userInfo['RegNo'] as String? ?? '',
      name: _titleCase(userInfo['UserName'] as String? ?? ''),
      department: userInfo['BranchName'] as String? ?? '',
      programme: userInfo['DegreeName'] as String? ?? '',
      currentSemester:
          int.tryParse(userInfo['SemesterNo']?.toString() ?? '') ?? 0,
    );

    final extSessions = data['ExternalSession'] as List<dynamic>? ?? [];
    _externalSessions = extSessions
        .map((s) => _SessionInfo(
              sessionNo:
                  int.tryParse(s['SessionNo']?.toString() ?? '') ?? 0,
              semesterNo:
                  int.tryParse(s['SemesterNo']?.toString() ?? '') ?? 0,
              sessionName: s['SessionName'] as String? ?? '',
            ))
        .toList()
      ..sort((a, b) => a.semesterNo.compareTo(b.semesterNo));
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([
        _loadProfile(),
        _loadAttendance(),
        _loadSchedule(),
        _loadExternalResults(),
        _loadInternalMarks(),
      ]);
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await api.getProfile();
      if (student != null) {
        student = Student.fromProfileResponse(data, base: student!);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('Profile load error: $e\n$st');
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final data = await api.getAttendance();
      final details = data['AttendanceDetails'] as List<dynamic>? ?? [];
      final studentCourses =
          _loginData?['StudentCourse'] as List<dynamic>? ?? [];

      final courseMap = <String, Map<String, dynamic>>{};
      for (final sc in studentCourses) {
        final no = sc['CourseNo'] as String? ?? '';
        courseMap[no] = sc as Map<String, dynamic>;
      }

      courses = details.map((att) {
        final a = att as Map<String, dynamic>;
        final courseNo = a['CourseNo'] as String? ?? '';
        final sc = courseMap[courseNo];

        final courseCode = sc?['CourseCode'] as String? ??
            _extractCode(a['Course_Name'] as String? ?? '');
        final courseName = sc?['CourseName'] as String? ??
            _extractName(a['Course_Name'] as String? ?? '');

        final type = _inferCourseType(courseName, courseCode,
            sc?['SubId'] as String?);

        return Course(
          code: courseCode,
          name: courseName,
          instructor: _titleCase(a['UaName'] as String? ?? '-'),
          totalClasses: (a['Total_Class'] as num?)?.toInt() ?? 0,
          attendedClasses: (a['Present'] as num?)?.toInt() ?? 0,
          type: type,
          courseNo: courseNo,
        );
      }).toList();

      notifyListeners();
    } catch (e, st) {
      debugPrint('Attendance load error: $e\n$st');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final data = await api.getSchedule();
      final tables = data['ClassTables'] as List<dynamic>?;
      if (tables == null) return;

      final entries = <ScheduleEntry>[];
      for (final day in tables) {
        final d = day as Map<String, dynamic>;
        final dayName = d['Day'] as String? ?? '';
        final dayOfWeek = _dayNameToNumber(dayName);
        final details = d['Detail'] as List<dynamic>? ?? [];

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

          // Format: "08:30 AM-09:20 AM" — split on the dash between the two times
          final timeMatch = RegExp(r'(.+\s*[AP]M)\s*-\s*(.+\s*[AP]M)')
              .firstMatch(lectureTime);
          final startTime = timeMatch?.group(1)?.trim() ?? '';
          final endTime = timeMatch?.group(2)?.trim() ?? '';

          entries.add(ScheduleEntry(
            courseCode: courseCode,
            courseName: courseName,
            instructor: '',
            room: section.isNotEmpty ? 'Sec $section' : '',
            startTime: startTime,
            endTime: endTime,
            dayOfWeek: dayOfWeek,
          ));
        }
      }

      schedule = _mergeConsecutiveEntries(entries);
      notifyListeners();
    } catch (e, st) {
      debugPrint('Schedule load error: $e\n$st');
    }
  }

  /// Merge consecutive periods on the same day for the same course into one entry.
  static List<ScheduleEntry> _mergeConsecutiveEntries(
      List<ScheduleEntry> entries) {
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

  Future<void> _loadExternalResults() async {
    final results = <SemesterResult>[];
    double? latestCgpa;
    int? cumulativeCredits;

    for (final session in _externalSessions) {
      try {
        final data = await api.getExternalResults(
          session.sessionNo,
          session.semesterNo,
        );

        final marks = data['ExternalMarks'] as List<dynamic>? ?? [];
        final resultInfo = data['Result'] as List<dynamic>? ?? [];
        final extResult =
            data['extStudentResult'] as Map<String, dynamic>? ?? {};

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

        latestCgpa = cgpa;
        cumulativeCredits = double.tryParse(
                extResult['CUMMULATIVE_CREDITS']?.toString() ?? '')
            ?.toInt();

        final grades = <CourseGrade>[];
        for (final mark in marks) {
          final m = mark as Map<String, dynamic>;
          final credit =
              double.tryParse(m['Credits']?.toString() ?? '') ?? 0;
          final grade = m['Grade'] as String? ?? '';
          semCredits += credit;
          grades.add(CourseGrade(
            courseCode: m['CourseCode'] as String? ?? '',
            courseName:
                (m['CourseName'] as String? ?? '').replaceAll('\u00a0', ' '),
            credits: credit,
            grade: grade,
            gradePoint: CourseGrade.gradeToPoint(grade),
          ));
        }

        results.add(SemesterResult(
          semester: session.semesterNo,
          sgpa: sgpa,
          cgpa: cgpa,
          creditsEarned: semCredits,
          grades: grades,
          result: extResult['PASSFAIL'] as String?,
        ));
      } catch (_) {}
    }

    semesterResults = results;

    if (student != null && latestCgpa != null) {

      student = student!.copyWith(
        cgpa: latestCgpa,
        totalCreditsEarned: cumulativeCredits,
      );
    }

    notifyListeners();
  }

  Future<void> _loadInternalMarks() async {
    try {
      isInternalMarksLoading = true;
      notifyListeners();

      final session = api.sessionNo;
      final semester = api.semesterNo;
      if (session == null || semester == null) return;

      final data = await api.getInternalMarks(session, semester);
      final marks = data['InternalMarks'] as List<dynamic>? ?? [];
      internalMarks = marks
          .map((m) => InternalMark.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('Internal marks load error: $e\n$st');
    } finally {
      isInternalMarksLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreSessionIfValid() async {
    final data = await prefs.loadPersistedSessionIfValid();
    if (data == null) return;

    _loginData = data;
    api.applyLoginResponse(data);
    _parseLoginData();
    isLoggedIn = true;
    isLoading = true;
    error = null;
    notifyListeners();

    await _loadAllData();
  }

  Future<void> logout() async {
    isLoggedIn = false;
    student = null;
    courses = [];
    schedule = [];
    semesterResults = [];
    internalMarks = [];
    _loginData = null;
    _externalSessions = [];
    api.uaNo = null;
    api.uaType = null;
    api.token = null;
    api.idNo = null;
    api.regNo = null;
    api.sessionNo = null;
    api.semesterNo = null;
    await prefs.clearPersistedSession();
    notifyListeners();
  }

  static String _extractCode(String combined) {
    final parts = combined.split(' - ');
    return parts.isNotEmpty ? parts[0].trim() : combined;
  }

  static String _extractName(String combined) {
    final idx = combined.indexOf(' - ');
    return idx >= 0 ? combined.substring(idx + 3).trim() : combined;
  }

  static String _titleCase(String text) {
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static CourseType _inferCourseType(
      String name, String code, String? subId) {
    final lower = name.toLowerCase();
    if (subId == '2' || lower.contains('laboratory') || lower.contains('lab')) {
      return CourseType.lab;
    }
    if (code.startsWith('OE') || code.startsWith('HS') || code.startsWith('VD')) {
      return CourseType.elective;
    }
    return CourseType.theory;
  }

  static int _dayNameToNumber(String day) {
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

class _SessionInfo {
  final int sessionNo;
  final int semesterNo;
  final String sessionName;

  _SessionInfo({
    required this.sessionNo,
    required this.semesterNo,
    required this.sessionName,
  });
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateScope>()!
        .notifier!;
  }
}
