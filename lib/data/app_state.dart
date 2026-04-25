import 'package:flutter/widgets.dart';
import 'api_service.dart';
import 'diary_data_repository.dart';
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
  late PrefsService _prefs;
  late DiaryDataRepository repository;

  PrefsService get prefs => _prefs;
  set prefs(PrefsService value) {
    _prefs = value;
    repository = DiaryDataRepository(api: api, prefs: value);
  }

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
  Future<void>? _fullSemesterResultsInFlight;
  bool _isMockSession = false;
  bool _isSilentRefresh = false;
  bool _isStartupRefreshLoading = false;
  bool _suppressSectionLoadersWithCachedData = false;
  bool _hasRestoredSnapshotData = false;
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
    _hasRestoredSnapshotData = false;
    _loginData = null;
    isLoggedIn = true;
    error = null;
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
      final entries = await repository.getAttendanceBySubject(courseNo);
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
  }

  Future<void> _reloadData() async {
    return _reloadDataImpl(this);
  }

  Future<void> _loadAllData() async {
    return _loadAllDataImpl(this);
  }

  /// Reloads all data required by the home/dashboard experience.
  Future<void> getHomeData({bool isStartup = false}) async {
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
    return getHomeData(isStartup: true);
  }

  Future<void> _performRefreshAllData({required bool isStartup}) async {
    return _performRefreshAllDataImpl(this, isStartup: isStartup);
  }

  /// Fetches every semester result for the Results screen and SGPA trend chart.
  Future<void> getSemResults() async {
    return _loadFullSemesterResultsImpl(this);
  }

  Future<void> _performFullSemesterResultsLoad() async {
    return _performFullSemesterResultsLoadImpl(this);
  }

  Future<void> restoreSessionIfValid() async {
    final data = await prefs.loadPersistedSession();
    if (data == null) return;

    _applyRestoredSession(data);

    final snapshot = await prefs.loadAppSnapshot();
    _hasRestoredSnapshotData = snapshot != null;
    _hydrateFromSnapshot(snapshot);
    notifyListeners();
  }

  Future<void> runStartupSyncInBackground() async {
    if (!isLoggedIn || _isMockSession) return;
    await refreshAllDataForStartup();
  }

  void _applyRestoredSession(Map<String, dynamic> data) {
    _applyRestoredSessionImpl(this, data);
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
