import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Set at build time: `flutter run --dart-define=API_DOMAIN=host.example.com`
  /// or `--dart-define-from-file=secrets.json` (copy secrets.example.json).
  static const String _apiDomain = String.fromEnvironment('API_DOMAIN');

  static String get _baseUrl {
    final host = _apiDomain.trim();
    if (host.isEmpty) {
      throw StateError(
        'API_DOMAIN is not set. Pass --dart-define=API_DOMAIN=<host> when building, '
        'or use --dart-define-from-file=secrets.json.',
      );
    }
    return 'https://$host/api/v2';
  }

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

    Map<String, dynamic>? data;
    final raw = response.body;
    if (raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Non-JSON body (e.g. HTML error page)
      }
    }

    // Failed auth often returns 3xx with JSON: IsErrorInService + Message.
    if (data != null && data['IsErrorInService'] == true) {
      throw ApiException(
        data['Message'] as String? ?? 'Invalid username or password',
      );
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      throw ApiException(
        data?['Message'] as String? ?? 'Login failed (${response.statusCode})',
      );
    }

    if (data == null) {
      throw ApiException('Login failed: could not read server response');
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
