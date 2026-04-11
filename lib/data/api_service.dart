import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const _baseUrl = 'https://android.svce.ac.in/api/v2';

  String? uaNo;
  String? uaType;
  String? token;
  String? idNo;
  String? regNo;
  int? sessionNo;
  int? semesterNo;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (uaNo != null) 'id': uaNo!,
        if (uaType != null) 'uatype': uaType!,
        if (token != null) 'token': token!,
      };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$path'),
      headers: _authHeaders,
      body: body,
    );
    if (response.statusCode == 401) {
      throw ApiException('Session expired. Please login again.');
    }
    if (response.statusCode != 200) {
      throw ApiException('Server error (${response.statusCode})');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['IsErrorInService'] == true) {
      throw ApiException(data['Message'] as String? ?? 'Unknown error');
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/initial/auth'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    if (response.statusCode != 200) {
      throw ApiException('Login failed (${response.statusCode})');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['IsErrorInService'] == true) {
      throw ApiException(data['Message'] as String? ?? 'Login failed');
    }

    applyLoginResponse(data);
    return data;
  }

  /// Restores auth headers from a stored login response (cold start) or fresh login.
  void applyLoginResponse(Map<String, dynamic> data) {
    final userInfo = data['UserInfo'] as Map<String, dynamic>?;
    if (userInfo == null) return;
    uaNo = userInfo['UaNo'] as String?;
    uaType = userInfo['UaType']?.toString();
    token = userInfo['Token'] as String?;
    idNo = userInfo['IdNo'] as String?;
    regNo = userInfo['RegNo'] as String?;
    sessionNo = _parseInt(userInfo['SessionNo']);
    semesterNo = int.tryParse(userInfo['SemesterNo']?.toString() ?? '');
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _post('information/stud', {'id': regNo!});
  }

  Future<Map<String, dynamic>> getSchedule() async {
    return _post('schedule/student', {
      'id': regNo!,
      'sessionno': sessionNo.toString(),
    });
  }

  Future<Map<String, dynamic>> getAttendance({int? session}) async {
    return _post('attendance/att', {
      'id': regNo!,
      'sessionno': (session ?? sessionNo).toString(),
    });
  }

  Future<Map<String, dynamic>> getExternalResults(
    int session,
    int semester,
  ) async {
    return _post('exam/ext', {
      'id': regNo!,
      'no': session.toString(),
      'sem': semester.toString(),
    });
  }

  Future<Map<String, dynamic>> getAttendanceBySubject(String courseNo) async {
    return _post('attendance/attsub', {
      'id': regNo!,
      'sub': courseNo,
      'sessionno': sessionNo.toString(),
    });
  }

  Future<Map<String, dynamic>> getInternalMarks(
    int session,
    int semester,
  ) async {
    return _post('exam/int', {
      'id': regNo!,
      'no': session.toString(),
      'sem': semester.toString(),
    });
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
