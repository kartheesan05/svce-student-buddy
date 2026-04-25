part of 'app_state.dart';

Future<void> _persistAppSnapshotImpl(AppState state) async {
  if (!state.isLoggedIn || state._isMockSession) return;
  try {
    await state.prefs.saveAppSnapshot(state._buildSnapshot());
  } catch (e, st) {
    debugPrint('Persist app snapshot error: $e\n$st');
  }
}

Map<String, dynamic> _buildSnapshotImpl(AppState state) {
  return {
    'version': 1,
    'student': AppStateSnapshotCodec.studentToJson(state.student),
    'courses': state.courses.map(AppStateSnapshotCodec.courseToJson).toList(),
    'schedule': state.schedule.map(AppStateSnapshotCodec.scheduleEntryToJson).toList(),
    'semesterResults': state.semesterResults
        .map(AppStateSnapshotCodec.semesterResultToJson)
        .toList(),
    'internalMarks': state.internalMarks
        .map(AppStateSnapshotCodec.internalMarkToJson)
        .toList(),
    'attendanceBySubject': state._attendanceBySubjectCache.map(
      (courseNo, entries) => MapEntry(
        courseNo,
        entries.map(AppStateSnapshotCodec.attendanceEntryToJson).toList(),
      ),
    ),
  };
}

void _hydrateFromSnapshotImpl(AppState state, Map<String, dynamic>? snapshot) {
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
        state.student = parsedStudent;
      }
    }
    if (rawCourses is List) {
      state.courses = rawCourses
          .whereType<Map<String, dynamic>>()
          .map(AppStateSnapshotCodec.courseFromJson)
          .toList();
    }
    if (rawSchedule is List) {
      state.schedule = rawSchedule
          .whereType<Map<String, dynamic>>()
          .map(AppStateSnapshotCodec.scheduleEntryFromJson)
          .toList();
    }
    if (rawSemesterResults is List) {
      state.semesterResults = rawSemesterResults
          .whereType<Map<String, dynamic>>()
          .map(AppStateSnapshotCodec.semesterResultFromJson)
          .toList();
    }
    if (rawInternalMarks is List) {
      state.internalMarks = rawInternalMarks
          .whereType<Map<String, dynamic>>()
          .map(AppStateSnapshotCodec.internalMarkFromJson)
          .toList();
    }
    if (rawAttendanceBySubject is Map) {
      state._attendanceBySubjectCache.clear();
      for (final entry in rawAttendanceBySubject.entries) {
        final courseNo = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          final parsed = value
              .whereType<Map<String, dynamic>>()
              .map(AppStateSnapshotCodec.attendanceEntryFromJson)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          state._attendanceBySubjectCache[courseNo] = parsed;
        }
      }
    }
  } catch (e, st) {
    debugPrint('Hydrate app snapshot error: $e\n$st');
  }
}
