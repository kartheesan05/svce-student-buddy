part of 'app_state.dart';

Future<void> _loadFullSemesterResultsImpl(AppState state) async {
  if (state._isMockSession) {
    if (state.semesterResults.isEmpty) {
      state.semesterResults = mockSemesterResults();
    }
    state._notifyDirect();
    return;
  }
  if (!state.isLoggedIn || state._externalSessions.isEmpty) {
    state.semesterResults = [];
    state._notifyDirect();
    return;
  }
  if (state.semesterResults.length == state._externalSessions.length &&
      state.semesterResults.isNotEmpty) {
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

  final results = <SemesterResult>[];
  double? latestCgpa;
  int? cumulativeCredits;

  try {
    final outcomes = await Future.wait(
      state._externalSessions.map((session) async {
        try {
          final data = await state.api.getExternalResults(
            session.sessionNo,
            session.semesterNo,
          );
          final parsed = state._semesterResultFromApiData(data, session);
          return (parsed, data);
        } catch (e, st) {
          await state._handleApiError(
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
          final extResult = data['extStudentResult'] as Map<String, dynamic>? ?? {};
          cumulativeCredits = double.tryParse(
            extResult['CUMMULATIVE_CREDITS']?.toString() ?? '',
          )?.toInt();
        }
      }
    }

    state.semesterResults = results;

    if (state.student != null && latestCgpa != null) {
      state.student = state.student!.copyWith(
        cgpa: latestCgpa,
        totalCreditsEarned: cumulativeCredits,
      );
    }
    await state._persistAppSnapshot();
  } finally {
    state.isSemesterResultsListLoading = false;
    state._notifyMaybe();
  }
}

SemesterResult? _semesterResultFromApiDataImpl(
  AppState state,
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
          courseName: (m['CourseName'] as String? ?? '').replaceAll('\u00a0', ' '),
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
