import 'package:flutter/widgets.dart';
import 'api_service.dart';
import 'app_state_snapshot_codec.dart';
import 'app_state_utils.dart';
import 'models/attendance_entry.dart';
import 'models/course.dart';
import 'models/internal_mark.dart';
import 'models/schedule_entry.dart';
import 'models/semester_result.dart';
import 'models/student.dart';
import 'mock_data.dart';
import 'prefs_service.dart';

part 'app_state_loaders.dart';

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

bool _isLikelyNetworkIssue(Object error) {
  if (error is ApiException) {
    final message = error.message.toLowerCase();
    if (message.contains("can't reach the server") ||
        message.contains('check your internet connection')) {
      return true;
    }
  }
  final s = error.toString();
  return s.contains('Failed host lookup') ||
      s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('Network is unreachable') ||
      s.contains('Connection timed out');
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
  bool _isHandlingSessionExpiry = false;
  bool _isSilentRefresh = false;
  bool _isStartupRefreshLoading = false;
  bool _suppressSectionLoadersWithCachedData = false;
  bool _hasRestoredSnapshotData = false;
  bool _sessionRefreshTriggeredDuringReload = false;
  Future<void>? _refreshAllDataInFlight;
  String? _pendingToastMessage;
  DateTime? _lastNetworkToastAt;
  final Map<String, List<AttendanceEntry>> _mockAttendanceBySubject = {};
  final Map<String, List<AttendanceEntry>> _attendanceBySubjectCache = {};

  bool get isStartupRefreshLoading => _isStartupRefreshLoading;
  String? consumeToastMessage() {
    final message = _pendingToastMessage;
    _pendingToastMessage = null;
    return message;
  }

  void _notifyMaybe() {
    if (_isSilentRefresh) return;
    notifyListeners();
  }

  void _notifyDirect() {
    notifyListeners();
  }

  Future<void> _handleApiError(
    Object error,
    StackTrace stackTrace,
    String context,
  ) async {
    debugPrint('$context error: $error\n$stackTrace');
    _maybeQueueNetworkIssueToast(error);
    if (_isHandlingSessionExpiry) return;
    if (error is! ApiException || !error.message.contains('Session expired')) {
      return;
    }
    _isHandlingSessionExpiry = true;
    this.error = error.message;
    try {
      final refreshed = await _tryRefreshSessionWithStoredCredentials();
      if (refreshed) {
        _sessionRefreshTriggeredDuringReload = true;
      }
    } finally {
      _isHandlingSessionExpiry = false;
    }
  }

  void _maybeQueueNetworkIssueToast(Object error) {
    if (!_isLikelyNetworkIssue(error)) return;
    final now = DateTime.now();
    final lastShownAt = _lastNetworkToastAt;
    if (lastShownAt != null &&
        now.difference(lastShownAt) < const Duration(seconds: 6)) {
      return;
    }
    _lastNetworkToastAt = now;
    _queueToast(
      "Can't reach the server. Check your internet connection and try again.",
    );
  }

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
      _hasRestoredSnapshotData = false;
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
    _hasRestoredSnapshotData = false;
    _loginData = null;
    isLoggedIn = true;
    error = null;
    _externalSessions = [];
    _fullSemesterResultsInFlight = null;

    student = mockStudent();
    courses = mockCourses();
    schedule = mockSchedule();
    semesterResults = mockSemesterResults();
    internalMarks = mockInternalMarks();
    _mockAttendanceBySubject
      ..clear()
      ..addAll(mockAttendanceLogsBySubject());

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
    final cached = _attendanceBySubjectCache[courseNo];
    if (cached != null) {
      return List<AttendanceEntry>.from(cached)
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    try {
      final data = await api.getAttendanceBySubject(courseNo);
      final list = data['AttendanceBySubject'] as List<dynamic>? ?? [];
      final entries =
          list
              .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      _attendanceBySubjectCache[courseNo] = List<AttendanceEntry>.from(entries);
      await _persistAppSnapshot();
      return entries;
    } catch (e, st) {
      await _handleApiError(e, st, 'Attendance by subject load');
      rethrow;
    }
  }

  void _parseLoginData() {
    final data = _loginData!;
    final userInfo = data['UserInfo'] as Map<String, dynamic>;

    student = Student(
      id: userInfo['RegNo'] as String? ?? '',
      name: AppStateUtils.titleCase(userInfo['UserName'] as String? ?? ''),
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
    return _reloadDataImpl(this);
  }

  Future<void> _runDataLoaders() async {
    return _runDataLoadersImpl(this);
  }

  Future<void> _loadAllData() async {
    return _loadAllDataImpl(this);
  }

  /// Reloads profile, courses, schedule, latest CGPA, and internal marks from the API.
  /// Full semester lists for the Results screen are loaded via [loadFullSemesterResults].
  Future<void> refreshAllData({bool isStartup = false}) async {
    if (!isLoggedIn) return;
    if (_isMockSession) {
      notifyListeners();
      return;
    }

    if (_refreshAllDataInFlight != null) {
      await _refreshAllDataInFlight;
      return;
    }

    final run = _performRefreshAllData(isStartup: isStartup);
    _refreshAllDataInFlight = run;
    try {
      await run;
    } finally {
      _refreshAllDataInFlight = null;
    }
  }

  Future<void> refreshAllDataForStartup() {
    return refreshAllData(isStartup: true);
  }

  Future<void> _performRefreshAllData({required bool isStartup}) async {
    return _performRefreshAllDataImpl(this, isStartup: isStartup);
  }

  Future<void> _loadProfile() async {
    return _loadProfileImpl(this);
  }

  Future<void> _loadAttendance() async {
    return _loadAttendanceImpl(this);
  }

  Future<void> _loadSchedule() async {
    return _loadScheduleImpl(this);
  }

  /// One request for the highest [semesterNo] in [ExternalSession] — updates [student] CGPA.
  /// Clears [semesterResults]; use [loadFullSemesterResults] on the Results screen.
  Future<void> _loadLatestExternalCgpa() async {
    return _loadLatestExternalCgpaImpl(this);
  }

  /// Fetches every semester in [ExternalSession] for the Results screen and SGPA trend chart.
  Future<void> loadFullSemesterResults() async {
    if (_isMockSession) {
      if (semesterResults.isEmpty) {
        semesterResults = mockSemesterResults();
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
    _notifyMaybe();

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
          } catch (e, st) {
            await _handleApiError(
              e,
              st,
              'Full semester results load (sem ${session.semesterNo})',
            );
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
      await _persistAppSnapshot();
    } finally {
      isSemesterResultsListLoading = false;
      _notifyMaybe();
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
    return _loadInternalMarksImpl(this);
  }

  Future<void> restoreSessionIfValid() async {
    final state = await prefs.loadPersistedSessionState();
    if (state == null) return;

    _applyRestoredSession(state.loginData);

    final snapshot = await prefs.loadAppSnapshot();
    _hasRestoredSnapshotData = snapshot != null;
    _hydrateFromSnapshot(snapshot);
    notifyListeners();

    if (state.isExpired) {
      await _tryRefreshSessionWithStoredCredentials();
    }
  }

  void _applyRestoredSession(Map<String, dynamic> data) {
    _isMockSession = false;
    _loginData = data;
    api.applyLoginResponse(data);
    _parseLoginData();
    isLoggedIn = true;
    isLoading = false;
    error = null;
  }

  Future<bool> _tryRefreshSessionWithStoredCredentials() async {
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
      _applyRestoredSession(refreshedLogin);
      await prefs.savePersistedSession(refreshedLogin);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _queueToast("Session expired, cannot refresh. Please logout and login again.");
      _maybeQueueNetworkIssueToast(e);
      return false;
    } catch (e) {
      _maybeQueueNetworkIssueToast(e);
      return false;
    }
  }

  String _normalizeUsername(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'@svce\.ac\.in$', caseSensitive: false), '')
        .trim();
  }

  void _queueToast(String message) {
    _pendingToastMessage = message;
    notifyListeners();
  }

  Future<void> logout() async {
    _isMockSession = false;
    isLoggedIn = false;
    student = null;
    courses = [];
    schedule = [];
    semesterResults = [];
    internalMarks = [];
    _attendanceBySubjectCache.clear();
    isExternalResultsLoading = false;
    isSemesterResultsListLoading = false;
    isProfileLoading = false;
    isAttendanceLoading = false;
    isScheduleLoading = false;
    isInternalMarksLoading = false;
    _loginData = null;
    _mockAttendanceBySubject.clear();
    _hasRestoredSnapshotData = false;
    _isStartupRefreshLoading = false;
    _suppressSectionLoadersWithCachedData = false;
    _sessionRefreshTriggeredDuringReload = false;
    _refreshAllDataInFlight = null;
    _pendingToastMessage = null;
    _externalSessions = [];
    api.uaNo = null;
    api.uaType = null;
    api.token = null;
    api.idNo = null;
    api.regNo = null;
    api.sessionNo = null;
    api.semesterNo = null;
    if (!prefs.rememberMe) {
      await prefs.clearCredentials();
    }
    await prefs.clearPersistedSession();
    await prefs.clearAppSnapshot();
    notifyListeners();
  }

  Future<void> _persistAppSnapshot() async {
    if (!isLoggedIn || _isMockSession) return;
    try {
      await prefs.saveAppSnapshot(_buildSnapshot());
    } catch (e, st) {
      debugPrint('Persist app snapshot error: $e\n$st');
    }
  }

  Map<String, dynamic> _buildSnapshot() {
    return {
      'version': 1,
      'student': AppStateSnapshotCodec.studentToJson(student),
      'courses': courses.map(AppStateSnapshotCodec.courseToJson).toList(),
      'schedule': schedule.map(AppStateSnapshotCodec.scheduleEntryToJson).toList(),
      'semesterResults': semesterResults
          .map(AppStateSnapshotCodec.semesterResultToJson)
          .toList(),
      'internalMarks': internalMarks
          .map(AppStateSnapshotCodec.internalMarkToJson)
          .toList(),
      'attendanceBySubject': _attendanceBySubjectCache.map(
        (courseNo, entries) => MapEntry(
          courseNo,
          entries.map(AppStateSnapshotCodec.attendanceEntryToJson).toList(),
        ),
      ),
    };
  }

  void _hydrateFromSnapshot(Map<String, dynamic>? snapshot) {
    if (snapshot == null) return;
    try {
      final rawStudent = snapshot['student'];
      final rawCourses = snapshot['courses'];
      final rawSchedule = snapshot['schedule'];
      final rawSemesterResults = snapshot['semesterResults'];
      final rawInternalMarks = snapshot['internalMarks'];
      final rawAttendanceBySubject = snapshot['attendanceBySubject'];

      if (rawStudent is Map<String, dynamic>) {
        final parsedStudent = AppStateSnapshotCodec.studentFromJson(rawStudent);
        if (parsedStudent != null) {
          student = parsedStudent;
        }
      }
      if (rawCourses is List) {
        courses = rawCourses
            .whereType<Map<String, dynamic>>()
            .map(AppStateSnapshotCodec.courseFromJson)
            .toList();
      }
      if (rawSchedule is List) {
        schedule = rawSchedule
            .whereType<Map<String, dynamic>>()
            .map(AppStateSnapshotCodec.scheduleEntryFromJson)
            .toList();
      }
      if (rawSemesterResults is List) {
        semesterResults = rawSemesterResults
            .whereType<Map<String, dynamic>>()
            .map(AppStateSnapshotCodec.semesterResultFromJson)
            .toList();
      }
      if (rawInternalMarks is List) {
        internalMarks = rawInternalMarks
            .whereType<Map<String, dynamic>>()
            .map(AppStateSnapshotCodec.internalMarkFromJson)
            .toList();
      }
      if (rawAttendanceBySubject is Map) {
        _attendanceBySubjectCache.clear();
        for (final entry in rawAttendanceBySubject.entries) {
          final courseNo = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            final parsed = value
                .whereType<Map<String, dynamic>>()
                .map(AppStateSnapshotCodec.attendanceEntryFromJson)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            _attendanceBySubjectCache[courseNo] = parsed;
          }
        }
      }
    } catch (e, st) {
      debugPrint('Hydrate app snapshot error: $e\n$st');
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
