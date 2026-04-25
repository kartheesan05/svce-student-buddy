part of 'app_state.dart';

Future<void> _reloadDataImpl(AppState state) async {
  state._sessionRefreshTriggeredDuringReload = false;
  try {
    await state._runDataLoaders();
    if (state._sessionRefreshTriggeredDuringReload) {
      state._sessionRefreshTriggeredDuringReload = false;
      await state._runDataLoaders();
    }
    await state._persistAppSnapshot();
  } catch (_) {}
  state._notifyDirect();
}

Future<void> _runDataLoadersImpl(AppState state) async {
  await Future.wait([
    state._loadProfile(),
    state._loadAttendance(),
    state._loadSchedule(),
    state._loadLatestExternalCgpa(),
    state._loadInternalMarks(),
  ]);
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

Future<void> _loadProfileImpl(AppState state) async {
  final hasCachedData = state._hasRestoredSnapshotData && state.student != null;
  state.isProfileLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedData);
  state._notifyMaybe();
  try {
    final data = await state.api.getProfile();
    if (state.student != null) {
      state.student = Student.fromProfileResponse(data, base: state.student!);
      state._notifyMaybe();
    }
  } catch (e, st) {
    await state._handleApiError(e, st, 'Profile load');
  } finally {
    state.isProfileLoading = false;
    state._notifyMaybe();
  }
}

Future<void> _loadAttendanceImpl(AppState state) async {
  final hasCachedData =
      state._hasRestoredSnapshotData && state.courses.isNotEmpty;
  state.isAttendanceLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedData);
  state._notifyMaybe();
  try {
    final data = await state.api.getAttendance();
    final details = data['AttendanceDetails'] as List<dynamic>? ?? [];
    final studentCourses = state._loginData?['StudentCourse'] as List<dynamic>? ?? [];

    final courseMap = <String, Map<String, dynamic>>{};
    for (final sc in studentCourses) {
      final no = sc['CourseNo'] as String? ?? '';
      courseMap[no] = sc as Map<String, dynamic>;
    }

    state.courses = details.map((att) {
      final a = att as Map<String, dynamic>;
      final courseNo = a['CourseNo'] as String? ?? '';
      final sc = courseMap[courseNo];

      final courseCode =
          sc?['CourseCode'] as String? ??
          AppStateUtils.extractCode(a['Course_Name'] as String? ?? '');
      final courseName =
          sc?['CourseName'] as String? ??
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

    state._notifyMaybe();
  } catch (e, st) {
    await state._handleApiError(e, st, 'Attendance load');
  } finally {
    state.isAttendanceLoading = false;
    state._notifyMaybe();
  }
}

Future<void> _loadScheduleImpl(AppState state) async {
  final hasCachedData =
      state._hasRestoredSnapshotData && state.schedule.isNotEmpty;
  state.isScheduleLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedData);
  state._notifyMaybe();
  try {
    final data = await state.api.getSchedule();
    final tables = data['ClassTables'] as List<dynamic>?;
    if (tables == null) return;

    final entries = <ScheduleEntry>[];
    for (final day in tables) {
      final d = day as Map<String, dynamic>;
      final dayName = d['Day'] as String? ?? '';
      final dayOfWeek = AppStateUtils.dayNameToNumber(dayName);
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

    state.schedule = _mergeConsecutiveEntries(entries);
    state._notifyMaybe();
  } catch (e, st) {
    await state._handleApiError(e, st, 'Schedule load');
  } finally {
    state.isScheduleLoading = false;
    state._notifyMaybe();
  }
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

Future<void> _loadLatestExternalCgpaImpl(AppState state) async {
  final hasCachedData =
      state._hasRestoredSnapshotData && state.student?.cgpa != null;
  state.isExternalResultsLoading =
      !(state._suppressSectionLoadersWithCachedData && hasCachedData);
  state._notifyMaybe();

  try {
    if (state._externalSessions.isEmpty) {
      return;
    }

    final latest = state._externalSessions.last;
    final data = await state.api.getExternalResults(
      latest.sessionNo,
      latest.semesterNo,
    );

    final parsed = state._semesterResultFromApiData(data, latest);
    if (parsed != null && state.student != null) {
      final extResult = data['extStudentResult'] as Map<String, dynamic>? ?? {};
      final cumulativeCredits = double.tryParse(
        extResult['CUMMULATIVE_CREDITS']?.toString() ?? '',
      )?.toInt();
      state.student = state.student!.copyWith(
        cgpa: parsed.cgpa,
        totalCreditsEarned: cumulativeCredits,
      );
    }
  } catch (e, st) {
    await state._handleApiError(e, st, 'Latest external results load');
  } finally {
    state.isExternalResultsLoading = false;
    state._notifyMaybe();
  }
}

Future<void> _loadInternalMarksImpl(AppState state) async {
  try {
    final hasCachedData =
        state._hasRestoredSnapshotData && state.internalMarks.isNotEmpty;
    state.isInternalMarksLoading =
        !(state._suppressSectionLoadersWithCachedData && hasCachedData);
    state._notifyMaybe();

    final session = state.api.sessionNo;
    final semester = state.api.semesterNo;
    if (session == null || semester == null) return;

    final data = await state.api.getInternalMarks(session, semester);
    final marks = data['InternalMarks'] as List<dynamic>? ?? [];
    state.internalMarks = marks
        .map((m) => InternalMark.fromJson(m as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    await state._handleApiError(e, st, 'Internal marks load');
  } finally {
    state.isInternalMarksLoading = false;
    state._notifyMaybe();
  }
}
