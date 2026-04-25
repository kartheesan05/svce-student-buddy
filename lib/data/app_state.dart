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
part 'app_state_errors.dart';
part 'app_state_results.dart';
part 'app_state_session.dart';
part 'app_state_snapshot.dart';

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
  bool _restoredSessionWasExpired = false;
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
    return _handleApiErrorImpl(this, error, stackTrace, context);
  }

  void _maybeQueueNetworkIssueToast(Object error) {
    _maybeQueueNetworkIssueToastImpl(this, error);
  }

  Future<String?> login(String username, String password) async {
    return _loginImpl(this, username, password);
  }

  bool _isMockCredentialLogin(String username, String password) {
    return username.trim().toLowerCase() == testLoginUsername &&
        password == testLoginPassword;
  }

  void _loginWithMockData() {
    _isMockSession = true;
    _restoredSessionWasExpired = false;
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
    return _loadFullSemesterResultsImpl(this);
  }

  Future<void> _performFullSemesterResultsLoad() async {
    return _performFullSemesterResultsLoadImpl(this);
  }

  SemesterResult? _semesterResultFromApiData(
    Map<String, dynamic> data,
    _SessionInfo session,
  ) {
    return _semesterResultFromApiDataImpl(this, data, session);
  }

  Future<void> _loadInternalMarks() async {
    return _loadInternalMarksImpl(this);
  }

  Future<void> restoreSessionIfValid() async {
    final state = await prefs.loadPersistedSessionState();
    if (state == null) return;

    _applyRestoredSession(state.loginData);
    _restoredSessionWasExpired = state.isExpired;

    final snapshot = await prefs.loadAppSnapshot();
    _hasRestoredSnapshotData = snapshot != null;
    _hydrateFromSnapshot(snapshot);
    notifyListeners();
  }

  Future<void> runStartupSyncInBackground() async {
    if (!isLoggedIn || _isMockSession) return;
    if (_restoredSessionWasExpired) {
      await _tryRefreshSessionWithStoredCredentials();
    }
    await refreshAllDataForStartup();
  }

  void _applyRestoredSession(Map<String, dynamic> data) {
    _applyRestoredSessionImpl(this, data);
  }

  Future<bool> _tryRefreshSessionWithStoredCredentials() async {
    return _tryRefreshSessionWithStoredCredentialsImpl(this);
  }

  String _normalizeUsername(String value) {
    return _normalizeUsernameImpl(this, value);
  }

  void _queueToast(String message) {
    _queueToastImpl(this, message);
  }

  Future<void> logout() async {
    return _logoutImpl(this);
  }

  Future<void> _persistAppSnapshot() async {
    return _persistAppSnapshotImpl(this);
  }

  Map<String, dynamic> _buildSnapshot() {
    return _buildSnapshotImpl(this);
  }

  void _hydrateFromSnapshot(Map<String, dynamic>? snapshot) {
    _hydrateFromSnapshotImpl(this, snapshot);
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
