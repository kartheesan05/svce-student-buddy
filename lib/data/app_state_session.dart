part of 'app_state.dart';

Future<String?> _loginImpl(
  AppState state,
  String username,
  String password,
) async {
  try {
    state.isLoading = true;
    state.error = null;
    state._notifyDirect();

    if (state._isMockCredentialLogin(username, password)) {
      state._loginWithMockData();
      state.isLoading = false;
      state._notifyDirect();
      return null;
    }

    state._isMockSession = false;
    state._hasRestoredSnapshotData = false;
    state._loginData = await state.api.login(username, password);
    state.isLoggedIn = true;
    state._parseLoginData();
    await state.prefs.savePersistedSession(state._loginData!);
    state._notifyDirect();

    state._loadAllData();
    return null;
  } on ApiException catch (e) {
    state.error = e.message;
    state.isLoading = false;
    state._notifyDirect();
    return e.message;
  } catch (e) {
    final message = _userVisibleNetworkError(e);
    state.error = message;
    state.isLoading = false;
    state._notifyDirect();
    return message;
  }
}

void _applyRestoredSessionImpl(AppState state, Map<String, dynamic> data) {
  state._isMockSession = false;
  state._loginData = data;
  state.api.applyLoginResponse(data);
  state._parseLoginData();
  state.isLoggedIn = true;
  state.isLoading = false;
  state.error = null;
}

Future<bool> _tryRefreshSessionWithStoredCredentialsImpl(AppState state) async {
  final savedUsername = await state.prefs.getSavedUsername();
  final savedPassword = await state.prefs.getSavedPassword();
  if (savedUsername == null ||
      savedUsername.trim().isEmpty ||
      savedPassword == null ||
      savedPassword.isEmpty) {
    return false;
  }

  try {
    final refreshedLogin = await state.api.login(
      state._normalizeUsername(savedUsername),
      savedPassword,
    );
    state._applyRestoredSession(refreshedLogin);
    await state.prefs.savePersistedSession(refreshedLogin);
    state._notifyDirect();
    return true;
  } on ApiException catch (e) {
    state._queueToast("Session expired, cannot refresh. Please logout and login again.");
    state._maybeQueueNetworkIssueToast(e);
    return false;
  } catch (e) {
    state._maybeQueueNetworkIssueToast(e);
    return false;
  }
}

String _normalizeUsernameImpl(AppState state, String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'@svce\.ac\.in$', caseSensitive: false), '')
      .trim();
}

Future<void> _logoutImpl(AppState state) async {
  state._isMockSession = false;
  state.isLoggedIn = false;
  state.student = null;
  state.courses = [];
  state.schedule = [];
  state.semesterResults = [];
  state.internalMarks = [];
  state._attendanceBySubjectCache.clear();
  state.isExternalResultsLoading = false;
  state.isSemesterResultsListLoading = false;
  state.isProfileLoading = false;
  state.isAttendanceLoading = false;
  state.isScheduleLoading = false;
  state.isInternalMarksLoading = false;
  state._loginData = null;
  state._mockAttendanceBySubject.clear();
  state._hasRestoredSnapshotData = false;
  state._isStartupRefreshLoading = false;
  state._suppressSectionLoadersWithCachedData = false;
  state._sessionRefreshTriggeredDuringReload = false;
  state._refreshAllDataInFlight = null;
  state._pendingToastMessage = null;
  state._externalSessions = [];
  state.api.uaNo = null;
  state.api.uaType = null;
  state.api.token = null;
  state.api.idNo = null;
  state.api.regNo = null;
  state.api.sessionNo = null;
  state.api.semesterNo = null;
  if (!state.prefs.rememberMe) {
    await state.prefs.clearCredentials();
  }
  await state.prefs.clearPersistedSession();
  await state.prefs.clearAppSnapshot();
  state._notifyDirect();
}
