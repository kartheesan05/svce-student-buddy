import 'models/student.dart';
import 'models/course.dart';
import 'models/schedule_entry.dart';
import 'models/semester_result.dart';

class MockData {
  static const student = Student(
    id: 'CS21B1045',
    name: 'Jerry Thomas',
    email: 'jerry.thomas@university.edu',
    phone: '+91 98765 43210',
    department: 'Computer Science & Engineering',
    programme: 'B.Tech CSE',
    currentSemester: 6,
    enrollmentYear: '2021',
    cgpa: 8.72,
    totalCreditsEarned: 102,
  );

  static const courses = [
    Course(
      code: 'CS301',
      name: 'Data Structures & Algorithms',
      instructor: 'Dr. Anand Sharma',
      credits: 4,
      totalClasses: 38,
      attendedClasses: 32,
      room: 'Room 301',
      type: CourseType.theory,
    ),
    Course(
      code: 'CS302',
      name: 'Operating Systems',
      instructor: 'Prof. Rajesh Kumar',
      credits: 4,
      totalClasses: 38,
      attendedClasses: 35,
      room: 'Room 204',
      type: CourseType.theory,
    ),
    Course(
      code: 'CS303',
      name: 'Database Management Systems',
      instructor: 'Dr. Priya Gupta',
      credits: 3,
      totalClasses: 34,
      attendedClasses: 28,
      room: 'Room 401',
      type: CourseType.theory,
    ),
    Course(
      code: 'MA301',
      name: 'Probability & Statistics',
      instructor: 'Dr. Venkat Reddy',
      credits: 3,
      totalClasses: 36,
      attendedClasses: 30,
      room: 'Room 105',
      type: CourseType.theory,
    ),
    Course(
      code: 'CS304',
      name: 'Computer Networks',
      instructor: 'Prof. Meera Patel',
      credits: 4,
      totalClasses: 38,
      attendedClasses: 33,
      room: 'Room 301',
      type: CourseType.theory,
    ),
    Course(
      code: 'CS305',
      name: 'Systems Lab',
      instructor: 'Prof. Rajesh Kumar',
      credits: 2,
      totalClasses: 20,
      attendedClasses: 18,
      room: 'Lab 2',
      type: CourseType.lab,
    ),
    Course(
      code: 'HS301',
      name: 'Technical Communication',
      instructor: 'Dr. Kavita Singh',
      credits: 2,
      totalClasses: 20,
      attendedClasses: 14,
      room: 'Room 102',
      type: CourseType.elective,
    ),
  ];

  static const schedule = [
    // Monday
    ScheduleEntry(courseCode: 'CS301', courseName: 'Data Structures & Algorithms', instructor: 'Dr. Anand Sharma', room: 'Room 301', startTime: '09:00', endTime: '10:00', dayOfWeek: 1),
    ScheduleEntry(courseCode: 'CS302', courseName: 'Operating Systems', instructor: 'Prof. Rajesh Kumar', room: 'Room 204', startTime: '10:00', endTime: '11:00', dayOfWeek: 1),
    ScheduleEntry(courseCode: 'MA301', courseName: 'Probability & Statistics', instructor: 'Dr. Venkat Reddy', room: 'Room 105', startTime: '11:30', endTime: '12:30', dayOfWeek: 1),
    ScheduleEntry(courseCode: 'CS304', courseName: 'Computer Networks', instructor: 'Prof. Meera Patel', room: 'Room 301', startTime: '14:00', endTime: '15:00', dayOfWeek: 1),

    // Tuesday
    ScheduleEntry(courseCode: 'CS303', courseName: 'Database Management Systems', instructor: 'Dr. Priya Gupta', room: 'Room 401', startTime: '09:00', endTime: '10:00', dayOfWeek: 2),
    ScheduleEntry(courseCode: 'CS301', courseName: 'Data Structures & Algorithms', instructor: 'Dr. Anand Sharma', room: 'Room 301', startTime: '10:00', endTime: '11:00', dayOfWeek: 2),
    ScheduleEntry(courseCode: 'CS302', courseName: 'Operating Systems', instructor: 'Prof. Rajesh Kumar', room: 'Room 204', startTime: '11:30', endTime: '12:30', dayOfWeek: 2),
    ScheduleEntry(courseCode: 'HS301', courseName: 'Technical Communication', instructor: 'Dr. Kavita Singh', room: 'Room 102', startTime: '14:00', endTime: '15:00', dayOfWeek: 2),

    // Wednesday
    ScheduleEntry(courseCode: 'MA301', courseName: 'Probability & Statistics', instructor: 'Dr. Venkat Reddy', room: 'Room 105', startTime: '09:00', endTime: '10:00', dayOfWeek: 3),
    ScheduleEntry(courseCode: 'CS304', courseName: 'Computer Networks', instructor: 'Prof. Meera Patel', room: 'Room 301', startTime: '10:00', endTime: '11:00', dayOfWeek: 3),
    ScheduleEntry(courseCode: 'CS305', courseName: 'Systems Lab', instructor: 'Prof. Rajesh Kumar', room: 'Lab 2', startTime: '11:30', endTime: '13:30', dayOfWeek: 3),
    ScheduleEntry(courseCode: 'CS303', courseName: 'Database Management Systems', instructor: 'Dr. Priya Gupta', room: 'Room 401', startTime: '14:00', endTime: '15:00', dayOfWeek: 3),

    // Thursday
    ScheduleEntry(courseCode: 'CS302', courseName: 'Operating Systems', instructor: 'Prof. Rajesh Kumar', room: 'Room 204', startTime: '09:00', endTime: '10:00', dayOfWeek: 4),
    ScheduleEntry(courseCode: 'MA301', courseName: 'Probability & Statistics', instructor: 'Dr. Venkat Reddy', room: 'Room 105', startTime: '10:00', endTime: '11:00', dayOfWeek: 4),
    ScheduleEntry(courseCode: 'CS304', courseName: 'Computer Networks', instructor: 'Prof. Meera Patel', room: 'Lab 2', startTime: '11:30', endTime: '13:30', dayOfWeek: 4),
    ScheduleEntry(courseCode: 'CS301', courseName: 'Data Structures & Algorithms', instructor: 'Dr. Anand Sharma', room: 'Room 301', startTime: '14:00', endTime: '15:00', dayOfWeek: 4),

    // Friday
    ScheduleEntry(courseCode: 'CS303', courseName: 'Database Management Systems', instructor: 'Dr. Priya Gupta', room: 'Room 401', startTime: '09:00', endTime: '10:00', dayOfWeek: 5),
    ScheduleEntry(courseCode: 'HS301', courseName: 'Technical Communication', instructor: 'Dr. Kavita Singh', room: 'Room 102', startTime: '10:00', endTime: '11:00', dayOfWeek: 5),
    ScheduleEntry(courseCode: 'CS305', courseName: 'Systems Lab', instructor: 'Prof. Rajesh Kumar', room: 'Lab 2', startTime: '11:30', endTime: '13:30', dayOfWeek: 5),
  ];

  static const semesterResults = [
    SemesterResult(
      semester: 1,
      sgpa: 8.4,
      cgpa: 8.4,
      creditsEarned: 20,
      grades: [
        CourseGrade(courseCode: 'CS101', courseName: 'Intro to Programming', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'MA101', courseName: 'Calculus I', credits: 4, grade: 'B+', gradePoint: 8),
        CourseGrade(courseCode: 'PH101', courseName: 'Physics I', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'EE101', courseName: 'Basic Electronics', credits: 4, grade: 'B+', gradePoint: 8),
        CourseGrade(courseCode: 'HS101', courseName: 'English', credits: 4, grade: 'A-', gradePoint: 8),
      ],
    ),
    SemesterResult(
      semester: 2,
      sgpa: 8.6,
      cgpa: 8.5,
      creditsEarned: 22,
      grades: [
        CourseGrade(courseCode: 'CS102', courseName: 'OOP with Java', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'MA102', courseName: 'Calculus II', credits: 4, grade: 'A-', gradePoint: 8),
        CourseGrade(courseCode: 'PH102', courseName: 'Physics II', credits: 4, grade: 'B+', gradePoint: 8),
        CourseGrade(courseCode: 'CS103', courseName: 'Digital Logic', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'ME101', courseName: 'Engineering Drawing', credits: 3, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'HS102', courseName: 'Economics', credits: 3, grade: 'A-', gradePoint: 8),
      ],
    ),
    SemesterResult(
      semester: 3,
      sgpa: 8.9,
      cgpa: 8.63,
      creditsEarned: 20,
      grades: [
        CourseGrade(courseCode: 'CS201', courseName: 'Discrete Mathematics', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'CS202', courseName: 'Computer Architecture', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'CS203', courseName: 'Data Structures', credits: 4, grade: 'A+', gradePoint: 10),
        CourseGrade(courseCode: 'MA201', courseName: 'Linear Algebra', credits: 4, grade: 'B+', gradePoint: 8),
        CourseGrade(courseCode: 'HS201', courseName: 'Psychology', credits: 4, grade: 'A-', gradePoint: 8),
      ],
    ),
    SemesterResult(
      semester: 4,
      sgpa: 8.5,
      cgpa: 8.6,
      creditsEarned: 20,
      grades: [
        CourseGrade(courseCode: 'CS204', courseName: 'Design & Analysis of Algorithms', credits: 4, grade: 'A-', gradePoint: 8),
        CourseGrade(courseCode: 'CS205', courseName: 'Theory of Computation', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'CS206', courseName: 'Software Engineering', credits: 4, grade: 'B+', gradePoint: 8),
        CourseGrade(courseCode: 'MA202', courseName: 'Numerical Methods', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'HS202', courseName: 'Sociology', credits: 4, grade: 'B+', gradePoint: 8),
      ],
    ),
    SemesterResult(
      semester: 5,
      sgpa: 9.1,
      cgpa: 8.72,
      creditsEarned: 20,
      grades: [
        CourseGrade(courseCode: 'CS251', courseName: 'Machine Learning', credits: 4, grade: 'A+', gradePoint: 10),
        CourseGrade(courseCode: 'CS252', courseName: 'Compiler Design', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'CS253', courseName: 'Web Technologies', credits: 4, grade: 'A', gradePoint: 9),
        CourseGrade(courseCode: 'CS254', courseName: 'Information Security', credits: 4, grade: 'A-', gradePoint: 8),
        CourseGrade(courseCode: 'HS251', courseName: 'Management', credits: 4, grade: 'A', gradePoint: 9),
      ],
    ),
  ];
}
