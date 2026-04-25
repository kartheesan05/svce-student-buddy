part of 'app_state.dart';

Future<void> _reloadDataImpl(AppState state) async {
  final hasCachedStudent = state._hasRestoredSnapshotData && state.student != null;
  final hasCachedCourses =
      state._hasRestoredSnapshotData && state.courses.isNotEmpty;
  final hasCachedSchedule =
      state._hasRestoredSnapshotData && state.schedule.isNotEmpty;
  final hasCachedInternalMarks =
      state._hasRestoredSnapshotData && state.internalMarks.isNotEmpty;

  state.isProfileLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedStudent);
  state.isAttendanceLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedCourses);
  state.isScheduleLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedSchedule);
  state.isInternalMarksLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedInternalMarks);
  state.isExternalResultsLoading = state.isProfileLoading;
  state._notifyMaybe();

  try {
    final homeData = await state.repository.getHomeData();
    state.student = homeData.student;
    state.courses = homeData.courses;
    state.schedule = homeData.schedule;
    state.internalMarks = homeData.internalMarks;
    await state._persistAppSnapshot();
  } catch (e, st) {
    await state._handleApiError(e, st, 'Home data load');
  } finally {
    state.isProfileLoading = false;
    state.isAttendanceLoading = false;
    state.isScheduleLoading = false;
    state.isInternalMarksLoading = false;
    state.isExternalResultsLoading = false;
  }
  state._notifyDirect();
}

Future<void> _loadAllDataImpl(AppState state) async {
  await state._reloadData();
  state.isLoading = false;
  state._notifyDirect();
}

Future<void> _performRefreshAllDataImpl(
  AppState state, {
  required bool isStartup,
}) async {
  state._isSilentRefresh = true;
  state._attendanceBySubjectCache.clear();
  state._suppressSectionLoadersWithCachedData =
      isStartup && state._hasRestoredSnapshotData;
  if (isStartup) {
    state._isStartupRefreshLoading = true;
    state._notifyDirect();
  }
  try {
    await state._reloadData();
  } finally {
    state._isSilentRefresh = false;
    state._suppressSectionLoadersWithCachedData = false;
    if (isStartup) {
      state._isStartupRefreshLoading = false;
      state._notifyDirect();
    }
  }
}
