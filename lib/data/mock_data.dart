import 'models/course.dart';
import 'models/internal_mark.dart';
import 'models/schedule_entry.dart';
import 'models/semester_result.dart';
import 'models/student.dart';
import 'models/attendance_entry.dart';

Student mockStudent() {
  return const Student(
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
}

List<Course> mockCourses() {
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

List<ScheduleEntry> mockSchedule() {
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

List<SemesterResult> mockSemesterResults() {
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

List<InternalMark> mockInternalMarks() {
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

Map<String, List<AttendanceEntry>> mockAttendanceLogsBySubject() {
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

List<AttendanceEntry> _buildAttendanceEntries({
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
