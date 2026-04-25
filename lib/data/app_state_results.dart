part of 'app_state.dart';

Future<void> _loadFullSemesterResultsImpl(AppState state) async {
  if (state._isMockSession) {
    if (state.semesterResults.isEmpty) {
      state.semesterResults = mockSemesterResults();
    }
    state._notifyDirect();
    return;
  }
  if (!state.isLoggedIn) {
    state.semesterResults = [];
    state._notifyDirect();
    return;
  }
  if (state.semesterResults.isNotEmpty) {
    return;
  }
  if (state._fullSemesterResultsInFlight != null) {
    await state._fullSemesterResultsInFlight;
    return;
  }
  final run = state._performFullSemesterResultsLoad();
  state._fullSemesterResultsInFlight = run;
  try {
    await run;
  } finally {
    state._fullSemesterResultsInFlight = null;
  }
}

Future<void> _performFullSemesterResultsLoadImpl(AppState state) async {
  state.isSemesterResultsListLoading = true;
  state._notifyMaybe();

  try {
    final results = await state.repository.getSemResults();
    state.semesterResults = results;
    if (state.student != null && results.isNotEmpty) {
      final latestResult = results.last;
      state.student = state.student!.copyWith(
        cgpa: latestResult.cgpa,
      );
    }
    await state._persistAppSnapshot();
  } catch (e, st) {
    await state._handleApiError(e, st, 'Full semester results load');
  } finally {
    state.isSemesterResultsListLoading = false;
    state._notifyMaybe();
  }
}
