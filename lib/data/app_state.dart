import 'package:flutter/widgets.dart';
import 'api_service.dart';
import 'models/attendance_entry.dart';
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
  static const String testLoginUsername = '2023cs0000';
  static const String testLoginPassword = 'password';

  final ApiService api = ApiService();
  late final PrefsService prefs;

  Student? student;
  List<Course> courses = [];
  List<ScheduleEntry> schedule = [];
  List<SemesterResult> semesterResults = [];
  List<InternalMark> internalMarks = [];
  bool isInternalMarksLoading = false;
  bool isExternalResultsLoading = false;

  /// True while fetching all semesters for the Results screen (trend chart).
  bool isSemesterResultsListLoading = false;
  bool isProfileLoading = false;
  bool isAttendanceLoading = false;
  bool isScheduleLoading = false;

  bool isLoggedIn = false;
  bool isLoading = false;
  String? error;

  Map<String, dynamic>? _loginData;
  List<_SessionInfo> _externalSessions = [];
  Future<void>? _fullSemesterResultsInFlight;
  bool _isMockSession = false;
  final Map<String, List<AttendanceEntry>> _mockAttendanceBySubject = {};

  Future<String?> login(String username, String password) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      if (_isMockCredentialLogin(username, password)) {
        _loginWithMockData();
        isLoading = false;
        notifyListeners();
        return null;
      }

      _isMockSession = false;
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

  bool _isMockCredentialLogin(String username, String password) {
    return username.trim().toLowerCase() == testLoginUsername &&
        password == testLoginPassword;
  }

  void _loginWithMockData() {
    _isMockSession = true;
    _loginData = null;
    isLoggedIn = true;
    error = null;
    _externalSessions = [];
    _fullSemesterResultsInFlight = null;

    student = const Student(
      id: '2127230501000',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phone: '9876543210',
      department: 'Computer Science and Engineering',
      programme: 'B.E CSE',
      currentSemester: 6,
      enrollmentYear: '2023',
      cgpa: 8.22,
      totalCreditsEarned: 117,
      enrollmentNo: '2023CS0000',
      degree: 'B.E.',
      fatherName: 'Robert Doe',
      motherName: 'Jane Doe',
      gender: 'Male',
      dob: '12-12-2004',
      bloodGroup: 'B+',
      category: 'BCM',
      address: '123, Main Road',
      city: 'Chennai',
      state: 'Tamil Nadu',
      postalCode: '600056',
      transportRoute: '55 -Porur',
      boardingPoint: 'Poonamalle Byepass',
    );

    courses = _mockCourses();
    schedule = _mockSchedule();
    semesterResults = _mockSemesterResults();
    internalMarks = _mockInternalMarks();
    _mockAttendanceBySubject
      ..clear()
      ..addAll(_mockAttendanceLogsBySubject());

    isInternalMarksLoading = false;
    isExternalResultsLoading = false;
    isSemesterResultsListLoading = false;
    isProfileLoading = false;
    isAttendanceLoading = false;
    isScheduleLoading = false;
  }

  Future<List<AttendanceEntry>> getAttendanceBySubject(String courseNo) async {
    if (_isMockSession) {
      final entries = _mockAttendanceBySubject[courseNo] ?? const [];
      return List<AttendanceEntry>.from(entries)
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final data = await api.getAttendanceBySubject(courseNo);
    final list = data['AttendanceBySubject'] as List<dynamic>? ?? [];
    final entries =
        list
            .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
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
    _externalSessions =
        extSessions
            .map(
              (s) => _SessionInfo(
                sessionNo: int.tryParse(s['SessionNo']?.toString() ?? '') ?? 0,
                semesterNo:
                    int.tryParse(s['SemesterNo']?.toString() ?? '') ?? 0,
                sessionName: s['SessionName'] as String? ?? '',
              ),
            )
            .toList()
          ..sort((a, b) => a.semesterNo.compareTo(b.semesterNo));
  }

  Future<void> _reloadData() async {
    try {
      await Future.wait([
        _loadProfile(),
        _loadAttendance(),
        _loadSchedule(),
        _loadLatestExternalCgpa(),
        _loadInternalMarks(),
      ]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    await _reloadData();
    isLoading = false;
    notifyListeners();
  }

  /// Reloads profile, courses, schedule, latest CGPA, and internal marks from the API.
  /// Full semester lists for the Results screen are loaded via [loadFullSemesterResults].
  Future<void> refreshAllData() async {
    if (!isLoggedIn) return;
    if (_isMockSession) {
      notifyListeners();
      return;
    }
    await _reloadData();
  }

  Future<void> _loadProfile() async {
    isProfileLoading = true;
    notifyListeners();
    try {
      final data = await api.getProfile();
      if (student != null) {
        student = Student.fromProfileResponse(data, base: student!);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('Profile load error: $e\n$st');
    } finally {
      isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAttendance() async {
    isAttendanceLoading = true;
    notifyListeners();
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

        final courseCode =
            sc?['CourseCode'] as String? ??
            _extractCode(a['Course_Name'] as String? ?? '');
        final courseName =
            sc?['CourseName'] as String? ??
            _extractName(a['Course_Name'] as String? ?? '');

        final type = _inferCourseType(
          courseName,
          courseCode,
          sc?['SubId'] as String?,
        );

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
    } finally {
      isAttendanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSchedule() async {
    isScheduleLoading = true;
    notifyListeners();
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
          final timeMatch = RegExp(
            r'(.+\s*[AP]M)\s*-\s*(.+\s*[AP]M)',
          ).firstMatch(lectureTime);
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

      schedule = _mergeConsecutiveEntries(entries);
      notifyListeners();
    } catch (e, st) {
      debugPrint('Schedule load error: $e\n$st');
    } finally {
      isScheduleLoading = false;
      notifyListeners();
    }
  }

  /// Merge consecutive periods on the same day for the same course into one entry.
  static List<ScheduleEntry> _mergeConsecutiveEntries(
    List<ScheduleEntry> entries,
  ) {
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

  /// One request for the highest [semesterNo] in [ExternalSession] — updates [student] CGPA.
  /// Clears [semesterResults]; use [loadFullSemesterResults] on the Results screen.
  Future<void> _loadLatestExternalCgpa() async {
    isExternalResultsLoading = true;
    semesterResults = [];
    notifyListeners();

    try {
      if (_externalSessions.isEmpty) {
        return;
      }

      final latest = _externalSessions.last;
      final data = await api.getExternalResults(
        latest.sessionNo,
        latest.semesterNo,
      );

      final parsed = _semesterResultFromApiData(data, latest);
      if (parsed != null && student != null) {
        final extResult =
            data['extStudentResult'] as Map<String, dynamic>? ?? {};
        final cumulativeCredits = double.tryParse(
          extResult['CUMMULATIVE_CREDITS']?.toString() ?? '',
        )?.toInt();
        student = student!.copyWith(
          cgpa: parsed.cgpa,
          totalCreditsEarned: cumulativeCredits,
        );
      }
    } catch (e, st) {
      debugPrint('Latest external results load error: $e\n$st');
    } finally {
      isExternalResultsLoading = false;
      notifyListeners();
    }
  }

  /// Fetches every semester in [ExternalSession] for the Results screen and SGPA trend chart.
  Future<void> loadFullSemesterResults() async {
    if (_isMockSession) {
      if (semesterResults.isEmpty) {
        semesterResults = _mockSemesterResults();
      }
      notifyListeners();
      return;
    }
    if (!isLoggedIn || _externalSessions.isEmpty) {
      semesterResults = [];
      notifyListeners();
      return;
    }
    if (semesterResults.length == _externalSessions.length &&
        semesterResults.isNotEmpty) {
      return;
    }
    if (_fullSemesterResultsInFlight != null) {
      await _fullSemesterResultsInFlight;
      return;
    }
    final run = _performFullSemesterResultsLoad();
    _fullSemesterResultsInFlight = run;
    try {
      await run;
    } finally {
      _fullSemesterResultsInFlight = null;
    }
  }

  Future<void> _performFullSemesterResultsLoad() async {
    isSemesterResultsListLoading = true;
    notifyListeners();

    final results = <SemesterResult>[];
    double? latestCgpa;
    int? cumulativeCredits;

    try {
      final outcomes = await Future.wait(
        _externalSessions.map((session) async {
          try {
            final data = await api.getExternalResults(
              session.sessionNo,
              session.semesterNo,
            );
            final parsed = _semesterResultFromApiData(data, session);
            return (parsed, data);
          } catch (_) {
            return (null, null);
          }
        }),
      );

      for (final outcome in outcomes) {
        final parsed = outcome.$1;
        final data = outcome.$2;
        if (parsed != null) {
          results.add(parsed);
          latestCgpa = parsed.cgpa;
          if (data != null) {
            final extResult =
                data['extStudentResult'] as Map<String, dynamic>? ?? {};
            cumulativeCredits = double.tryParse(
              extResult['CUMMULATIVE_CREDITS']?.toString() ?? '',
            )?.toInt();
          }
        }
      }

      semesterResults = results;

      if (student != null && latestCgpa != null) {
        student = student!.copyWith(
          cgpa: latestCgpa,
          totalCreditsEarned: cumulativeCredits,
        );
      }
    } finally {
      isSemesterResultsListLoading = false;
      notifyListeners();
    }
  }

  SemesterResult? _semesterResultFromApiData(
    Map<String, dynamic> data,
    _SessionInfo session,
  ) {
    try {
      final marks = data['ExternalMarks'] as List<dynamic>? ?? [];
      final resultInfo = data['Result'] as List<dynamic>? ?? [];
      final extResult = data['extStudentResult'] as Map<String, dynamic>? ?? {};

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
            courseName: (m['CourseName'] as String? ?? '').replaceAll(
              '\u00a0',
              ' ',
            ),
            credits: credit,
            grade: grade,
            gradePoint: CourseGrade.gradeToPoint(grade),
          ),
        );
      }

      return SemesterResult(
        semester: session.semesterNo,
        sgpa: sgpa,
        cgpa: cgpa,
        creditsEarned: semCredits,
        grades: grades,
        result: extResult['PASSFAIL'] as String?,
      );
    } catch (e, st) {
      debugPrint('Parse external result error: $e\n$st');
      return null;
    }
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

    _isMockSession = false;
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
    _isMockSession = false;
    isLoggedIn = false;
    student = null;
    courses = [];
    schedule = [];
    semesterResults = [];
    internalMarks = [];
    isExternalResultsLoading = false;
    isSemesterResultsListLoading = false;
    isProfileLoading = false;
    isAttendanceLoading = false;
    isScheduleLoading = false;
    isInternalMarksLoading = false;
    _loginData = null;
    _mockAttendanceBySubject.clear();
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
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static CourseType _inferCourseType(String name, String code, String? subId) {
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

  static List<Course> _mockCourses() {
    return const [
      Course(
        code: 'CS22021',
        name: 'Exploratory Data Analysis',
        instructor: 'Arun Kumar',
        totalClasses: 45,
        attendedClasses: 40,
        type: CourseType.theory,
        courseNo: '7029',
      ),
      Course(
        code: 'OE22001',
        name: 'Green Manufacturing',
        instructor: 'Priya Raman',
        totalClasses: 31,
        attendedClasses: 10,
        type: CourseType.elective,
        courseNo: '7755',
      ),
      Course(
        code: 'CS22601',
        name: 'Cryptography and Network Security',
        instructor: 'Sathish Narayanan',
        totalClasses: 18,
        attendedClasses: 8,
        type: CourseType.theory,
        courseNo: '7966',
      ),
      Course(
        code: 'CS22602',
        name: 'Software Project Management',
        instructor: 'Meena Krishnan',
        totalClasses: 30,
        attendedClasses: 25,
        type: CourseType.theory,
        courseNo: '7967',
      ),
      Course(
        code: 'AD22501',
        name: 'Internet of Things and Applications',
        instructor: 'Vignesh Iyer',
        totalClasses: 30,
        attendedClasses: 10,
        type: CourseType.theory,
        courseNo: '7969',
      ),
      Course(
        code: 'CS22603',
        name: 'Cloud Computing',
        instructor: 'Karthik Rajan',
        totalClasses: 41,
        attendedClasses: 32,
        type: CourseType.theory,
        courseNo: '7970',
      ),
      Course(
        code: 'CS22604',
        name: 'Compiler Design',
        instructor: 'Nandhini Suresh',
        totalClasses: 34,
        attendedClasses: 29,
        type: CourseType.theory,
        courseNo: '7972',
      ),
      Course(
        code: 'CS22611',
        name: 'Cryptography and Network Security Laboratory',
        instructor: '-',
        totalClasses: 0,
        attendedClasses: 0,
        type: CourseType.lab,
        courseNo: '7973',
      ),
      Course(
        code: 'CS22612',
        name: 'Cloud Computing Laboratory',
        instructor: 'Karthik Rajan',
        totalClasses: 12,
        attendedClasses: 12,
        type: CourseType.lab,
        courseNo: '7974',
      ),
    ];
  }

  static List<ScheduleEntry> _mockSchedule() {
    return const [
      ScheduleEntry(
        courseCode: 'CS22021',
        courseName: 'Exploratory Data Analysis',
        instructor: 'Arun Kumar',
        room: 'Sec A',
        startTime: '08:30 AM',
        endTime: '09:20 AM',
        dayOfWeek: 1,
      ),
      ScheduleEntry(
        courseCode: 'CS22603',
        courseName: 'Cloud Computing',
        instructor: 'Karthik Rajan',
        room: 'Sec A',
        startTime: '09:20 AM',
        endTime: '10:10 AM',
        dayOfWeek: 1,
      ),
      ScheduleEntry(
        courseCode: 'CS22601',
        courseName: 'Cryptography and Network Security',
        instructor: 'Sathish Narayanan',
        room: 'Sec A',
        startTime: '10:20 AM',
        endTime: '11:10 AM',
        dayOfWeek: 2,
      ),
      ScheduleEntry(
        courseCode: 'CS22612',
        courseName: 'Cloud Computing Laboratory',
        instructor: 'Karthik Rajan',
        room: 'Lab',
        startTime: '01:10 PM',
        endTime: '03:00 PM',
        dayOfWeek: 2,
      ),
      ScheduleEntry(
        courseCode: 'OE22001',
        courseName: 'Green Manufacturing',
        instructor: 'Priya Raman',
        room: 'Seminar Hall',
        startTime: '10:20 AM',
        endTime: '11:10 AM',
        dayOfWeek: 3,
      ),
      ScheduleEntry(
        courseCode: 'CS22604',
        courseName: 'Compiler Design',
        instructor: 'Nandhini Suresh',
        room: 'Sec A',
        startTime: '11:10 AM',
        endTime: '12:00 PM',
        dayOfWeek: 4,
      ),
      ScheduleEntry(
        courseCode: 'AD22501',
        courseName: 'Internet of Things and Applications',
        instructor: 'Vignesh Iyer',
        room: 'Sec A',
        startTime: '02:00 PM',
        endTime: '02:50 PM',
        dayOfWeek: 5,
      ),
    ];
  }

  static List<SemesterResult> _mockSemesterResults() {
    return const [
      SemesterResult(
        semester: 1,
        sgpa: 8.30,
        cgpa: 8.30,
        creditsEarned: 23.5,
        result: 'PASS',
        grades: [
          CourseGrade(
            courseCode: 'MA22151',
            courseName: 'Applied Mathematics I',
            credits: 4,
            grade: 'A+',
            gradePoint: 9,
          ),
          CourseGrade(
            courseCode: 'IT22101',
            courseName: 'Programming for Problem Solving',
            credits: 3,
            grade: 'A',
            gradePoint: 8,
          ),
        ],
      ),
      SemesterResult(
        semester: 2,
        sgpa: 8.13,
        cgpa: 8.21,
        creditsEarned: 47.5,
        result: 'PASS',
        grades: [
          CourseGrade(
            courseCode: 'CS22201',
            courseName: 'Python For Data Science',
            credits: 4,
            grade: 'A',
            gradePoint: 8,
          ),
          CourseGrade(
            courseCode: 'CS22211',
            courseName: 'Digital Principles and System Design Laboratory',
            credits: 1.5,
            grade: 'A+',
            gradePoint: 9,
          ),
        ],
      ),
      SemesterResult(
        semester: 3,
        sgpa: 8.19,
        cgpa: 8.20,
        creditsEarned: 71.0,
        result: 'PASS',
        grades: [
          CourseGrade(
            courseCode: 'CS22301',
            courseName: 'Database Management Systems',
            credits: 3,
            grade: 'A',
            gradePoint: 8,
          ),
          CourseGrade(
            courseCode: 'CS22311',
            courseName: 'Database Management Systems Laboratory',
            credits: 1.5,
            grade: 'O',
            gradePoint: 10,
          ),
        ],
      ),
      SemesterResult(
        semester: 4,
        sgpa: 8.20,
        cgpa: 8.20,
        creditsEarned: 94.0,
        result: 'PASS',
        grades: [
          CourseGrade(
            courseCode: 'CS22401',
            courseName: 'Operating Systems',
            credits: 3,
            grade: 'A',
            gradePoint: 8,
          ),
          CourseGrade(
            courseCode: 'CS22411',
            courseName: 'Operating Systems Laboratory',
            credits: 1.5,
            grade: 'O',
            gradePoint: 10,
          ),
        ],
      ),
      SemesterResult(
        semester: 5,
        sgpa: 8.30,
        cgpa: 8.22,
        creditsEarned: 117.0,
        result: 'PASS',
        grades: [
          CourseGrade(
            courseCode: 'CS22511',
            courseName: 'Computer Networks Laboratory',
            credits: 1.5,
            grade: 'O',
            gradePoint: 10,
          ),
          CourseGrade(
            courseCode: 'CS22501',
            courseName: 'Computer Networks',
            credits: 3,
            grade: 'A',
            gradePoint: 8,
          ),
        ],
      ),
    ];
  }

  static List<InternalMark> _mockInternalMarks() {
    return const [
      InternalMark(
        courseName: 'Exploratory Data Analysis',
        courseCode: 'CS22021',
        isLab: false,
        cat1: '-',
        cat2: '-',
        cat3: '-',
        asign1: '-',
        asign2: '-',
        asign3: '-',
        modelExam: '-',
      ),
      InternalMark(
        courseName: 'Internet of Things and Applications',
        courseCode: 'AD22501',
        isLab: false,
        cat1: '39.00',
        cat2: '-',
        cat3: '-',
        asign1: '48.00',
        asign2: '50.00',
        asign3: '-',
        modelExam: '-',
      ),
      InternalMark(
        courseName: 'Cloud Computing',
        courseCode: 'CS22603',
        isLab: false,
        cat1: '47.00',
        cat2: '-',
        cat3: '-',
        asign1: '47.00',
        asign2: '-',
        asign3: '-',
        modelExam: '-',
      ),
      InternalMark(
        courseName: 'Cryptography and Network Security Laboratory',
        courseCode: 'CS22611',
        isLab: true,
        cat1: '-',
        cat2: '-',
        cat3: '-',
        asign1: '-',
        asign2: '-',
        asign3: '-',
        modelExam: '-',
      ),
      InternalMark(
        courseName: 'Cloud Computing Laboratory',
        courseCode: 'CS22612',
        isLab: true,
        cat1: '-',
        cat2: '-',
        cat3: '-',
        asign1: '-',
        asign2: '-',
        asign3: '-',
        modelExam: '-',
      ),
    ];
  }

  static Map<String, List<AttendanceEntry>> _mockAttendanceLogsBySubject() {
    return {
      '7029': _buildAttendanceEntries(
        presentDates: [
          '07-01-2026',
          '08-01-2026',
          '09-01-2026',
          '12-01-2026',
          '15-01-2026',
          '16-01-2026',
          '19-01-2026',
          '21-01-2026',
          '23-01-2026',
          '28-01-2026',
          '29-01-2026',
          '30-01-2026',
          '02-02-2026',
          '04-02-2026',
          '05-02-2026',
          '06-02-2026',
          '09-02-2026',
          '11-02-2026',
          '12-02-2026',
          '16-02-2026',
          '18-02-2026',
          '19-02-2026',
          '20-02-2026',
          '23-02-2026',
          '26-02-2026',
          '02-03-2026',
          '04-03-2026',
          '05-03-2026',
          '06-03-2026',
          '09-03-2026',
          '11-03-2026',
          '12-03-2026',
          '13-03-2026',
          '16-03-2026',
          '18-03-2026',
          '20-03-2026',
        ],
        absentDates: ['14-01-2026', '22-01-2026', '25-02-2026', '27-02-2026'],
        onDutyDates: ['26-01-2026'],
      ),
      '7755': _buildAttendanceEntries(
        presentDates: [
          '09-01-2026',
          '16-01-2026',
          '23-01-2026',
          '30-01-2026',
          '06-02-2026',
          '13-02-2026',
          '20-02-2026',
          '27-02-2026',
          '06-03-2026',
          '13-03-2026',
        ],
        absentDates: [
          '08-01-2026',
          '15-01-2026',
          '22-01-2026',
          '29-01-2026',
          '05-02-2026',
          '12-02-2026',
          '19-02-2026',
          '26-02-2026',
          '05-03-2026',
          '12-03-2026',
          '19-03-2026',
          '20-03-2026',
        ],
        onDutyDates: ['26-01-2026'],
      ),
      '7966': _buildAttendanceEntries(
        presentDates: [
          '07-01-2026',
          '14-01-2026',
          '21-01-2026',
          '28-01-2026',
          '04-02-2026',
          '11-02-2026',
          '18-02-2026',
          '04-03-2026',
        ],
        absentDates: ['25-02-2026'],
      ),
      '7967': _buildAttendanceEntries(
        presentDates: [
          '12-01-2026',
          '19-01-2026',
          '26-01-2026',
          '02-02-2026',
          '09-02-2026',
          '16-02-2026',
          '23-02-2026',
          '02-03-2026',
          '09-03-2026',
          '16-03-2026',
        ],
        absentDates: ['30-01-2026'],
      ),
      '7969': _buildAttendanceEntries(
        presentDates: [
          '08-01-2026',
          '15-01-2026',
          '29-01-2026',
          '05-02-2026',
          '12-02-2026',
          '26-02-2026',
          '05-03-2026',
          '12-03-2026',
          '19-03-2026',
          '20-03-2026',
        ],
        absentDates: [
          '09-01-2026',
          '16-01-2026',
          '23-01-2026',
          '30-01-2026',
          '06-02-2026',
          '13-02-2026',
          '20-02-2026',
          '27-02-2026',
        ],
      ),
      '7970': _buildAttendanceEntries(
        presentDates: [
          '07-01-2026',
          '08-01-2026',
          '09-01-2026',
          '12-01-2026',
          '15-01-2026',
          '16-01-2026',
          '19-01-2026',
          '21-01-2026',
          '23-01-2026',
          '28-01-2026',
          '29-01-2026',
          '30-01-2026',
          '02-02-2026',
          '04-02-2026',
          '05-02-2026',
          '06-02-2026',
          '09-02-2026',
          '11-02-2026',
          '12-02-2026',
          '16-02-2026',
          '18-02-2026',
          '19-02-2026',
          '20-02-2026',
          '23-02-2026',
          '26-02-2026',
          '02-03-2026',
          '04-03-2026',
          '05-03-2026',
          '06-03-2026',
          '09-03-2026',
          '11-03-2026',
          '12-03-2026',
        ],
        absentDates: ['22-01-2026', '25-02-2026', '27-02-2026', '13-03-2026'],
      ),
      '7972': _buildAttendanceEntries(
        presentDates: [
          '07-01-2026',
          '14-01-2026',
          '21-01-2026',
          '28-01-2026',
          '04-02-2026',
          '11-02-2026',
          '18-02-2026',
          '19-02-2026',
          '20-02-2026',
          '04-03-2026',
          '11-03-2026',
          '18-03-2026',
        ],
        absentDates: ['25-02-2026', '27-02-2026'],
      ),
      '7973': const [],
      '7974': _buildAttendanceEntries(
        presentDates: [
          '02-02-2026',
          '05-02-2026',
          '09-02-2026',
          '11-02-2026',
          '16-02-2026',
          '18-02-2026',
          '23-02-2026',
          '02-03-2026',
          '09-03-2026',
          '16-03-2026',
          '20-03-2026',
          '19-03-2026',
        ],
      ),
    };
  }

  static List<AttendanceEntry> _buildAttendanceEntries({
    required List<String> presentDates,
    List<String> absentDates = const [],
    List<String> onDutyDates = const [],
  }) {
    final periodCycle = ['I', 'IV', 'V', 'VII'];
    final entries = <AttendanceEntry>[];
    var index = 0;

    void addEntries(List<String> dates, AttendanceStatus status) {
      for (final dateStr in dates) {
        final parts = dateStr.split('-');
        if (parts.length != 3) continue;
        final day = int.tryParse(parts[0]) ?? 1;
        final month = int.tryParse(parts[1]) ?? 1;
        final year = int.tryParse(parts[2]) ?? 2026;
        entries.add(
          AttendanceEntry(
            date: DateTime(year, month, day),
            period: periodCycle[index % periodCycle.length],
            status: status,
          ),
        );
        index++;
      }
    }

    addEntries(presentDates, AttendanceStatus.present);
    addEntries(absentDates, AttendanceStatus.absent);
    addEntries(onDutyDates, AttendanceStatus.onDuty);

    return entries..sort((a, b) => b.date.compareTo(a.date));
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
