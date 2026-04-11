import 'dart:convert';
import 'dart:typed_data';

class Student {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String department;
  final String programme;
  final int currentSemester;
  final String? enrollmentYear;
  final double? cgpa;
  final int? totalCreditsEarned;
  final String avatarUrl;

  final Uint8List? photoBytes;
  final String? enrollmentNo;
  final String? degree;
  final String? fatherName;
  final String? motherName;
  final String? gender;
  final String? dob;
  final String? bloodGroup;
  final String? category;

  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;

  final String? transportRoute;
  final String? boardingPoint;

  const Student({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.department,
    required this.programme,
    required this.currentSemester,
    this.enrollmentYear,
    this.cgpa,
    this.totalCreditsEarned,
    this.avatarUrl = '',
    this.photoBytes,
    this.enrollmentNo,
    this.degree,
    this.fatherName,
    this.motherName,
    this.gender,
    this.dob,
    this.bloodGroup,
    this.category,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.transportRoute,
    this.boardingPoint,
  });

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? programme,
    int? currentSemester,
    String? enrollmentYear,
    double? cgpa,
    int? totalCreditsEarned,
    String? avatarUrl,
    Uint8List? photoBytes,
    String? enrollmentNo,
    String? degree,
    String? fatherName,
    String? motherName,
    String? gender,
    String? dob,
    String? bloodGroup,
    String? category,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? transportRoute,
    String? boardingPoint,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      programme: programme ?? this.programme,
      currentSemester: currentSemester ?? this.currentSemester,
      enrollmentYear: enrollmentYear ?? this.enrollmentYear,
      cgpa: cgpa ?? this.cgpa,
      totalCreditsEarned: totalCreditsEarned ?? this.totalCreditsEarned,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photoBytes: photoBytes ?? this.photoBytes,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      degree: degree ?? this.degree,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      category: category ?? this.category,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      transportRoute: transportRoute ?? this.transportRoute,
      boardingPoint: boardingPoint ?? this.boardingPoint,
    );
  }

  static Uint8List? decodePhoto(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  static String? _findValue(List<dynamic>? entries, String key) {
    if (entries == null) return null;
    for (final entry in entries) {
      final m = entry as Map<String, dynamic>;
      if (m['Key'] == key) {
        final v = m['Value'] as String?;
        return (v == null || v == '-' || v.isEmpty) ? null : v;
      }
    }
    return null;
  }

  /// Find a value filtering by Type field for sections with multiple address types.
  static String? _findValueByType(
      List<dynamic>? entries, String type, String key) {
    if (entries == null) return null;
    for (final entry in entries) {
      final m = entry as Map<String, dynamic>;
      if (m['Type'] == type && m['Key'] == key) {
        final v = m['Value'] as String?;
        return (v == null || v == '-' || v.isEmpty) ? null : v;
      }
    }
    return null;
  }

  factory Student.fromProfileResponse(
    Map<String, dynamic> json, {
    required Student base,
  }) {
    final studentInfo = json['StudentInfo'] as List<dynamic>?;
    final contactInfo = json['ContactInfo'] as List<dynamic>?;
    final postalInfo = json['PostalInfo'] as List<dynamic>?;
    final transportInfo = json['transportInfo'] as List<dynamic>?;

    final email = _findValue(contactInfo, 'Email') ??
        _findValueByType(postalInfo, '3', 'Email');
    final phone = _findValue(contactInfo, 'Student Mobile No') ??
        _findValueByType(postalInfo, '3', 'Mobile');

    return base.copyWith(
      name: _titleCase(json['StudentName'] as String? ?? base.name),
      email: email,
      phone: phone,
      photoBytes: decodePhoto(json['Photo'] as String?),
      enrollmentNo: _findValue(studentInfo, 'Enrollment No'),
      degree: _findValue(studentInfo, 'Degree'),
      fatherName: _titleCase(_findValue(studentInfo, "Father's Name") ?? ''),
      motherName: _titleCase(_findValue(studentInfo, "Mother's Name") ?? ''),
      gender: _findValue(studentInfo, 'Gender'),
      dob: _findValue(studentInfo, 'DOB'),
      bloodGroup: _findValue(studentInfo, 'Blood Group'),
      category: _findValue(studentInfo, 'Category'),
      address: _findValueByType(postalInfo, '3', 'Address'),
      city: _findValueByType(postalInfo, '3', 'City'),
      state: _findValueByType(postalInfo, '3', 'State'),
      postalCode: _findValueByType(postalInfo, '3', 'Postal Code'),
      transportRoute: _findValue(transportInfo, 'ROUTE NAME'),
      boardingPoint: _findValue(transportInfo, 'BOARDING POINT'),
    );
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
