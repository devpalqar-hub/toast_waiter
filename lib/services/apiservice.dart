import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/tablemodel.dart';
import '../models/ordermodel.dart';
import '../models/menuitem.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool ok;
  ApiResponse.success(this.data)
      : ok = true,
        error = null;
  ApiResponse.failure(this.error)
      : ok = false,
        data = null;
}

class ApiService {
  static String? _token;
  static String? _restaurantId;
  static const _timeout = Duration(seconds: 15);

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = (await SharedPreferences.getInstance()).getString(C.tokenKey);
    return _token;
  }

  static Future<String?> getRestaurantId() async {
    if (_restaurantId != null) return _restaurantId;
    _restaurantId =
        (await SharedPreferences.getInstance()).getString(C.restaurantKey);
    return _restaurantId;
  }

  static String? _restaurantName;

  static Future<String> getRestaurantName() async {
    if (_restaurantName != null) return _restaurantName!;
    _restaurantName =
        (await SharedPreferences.getInstance()).getString(C.restaurantNameKey);
    return _restaurantName ?? 'Restaurant';
  }

  static Future<void> _saveSession(String token, String rId,
      {String? name}) async {
    _token = token;
    _restaurantId = rId;
    _restaurantName = name;
    final p = await SharedPreferences.getInstance();
    await p.setString(C.tokenKey, token);
    await p.setString(C.restaurantKey, rId);
    if (name != null) await p.setString(C.restaurantNameKey, name);
  }

  static Future<void> clearToken() async {
    _token = null;
    _restaurantId = null;
    _restaurantName = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(C.tokenKey);
    await p.remove(C.restaurantKey);
    await p.remove(C.restaurantNameKey);
  }

  static const Map<String, String> _pub = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> _auth() async {
    final t = await getToken();
    final h = Map<String, String>.from(_pub);
    if (t != null) h['Authorization'] = 'Bearer $t';
    return h;
  }

  static dynamic _json(http.Response r) {
    try {
      return jsonDecode(r.body);
    } catch (_) {
      return {};
    }
  }

  static List<dynamic> _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in ['data', 'items', 'sessions', 'results', 'records']) {
        if (d[k] is List) return d[k] as List<dynamic>;
      }
    }
    return [];
  }

  static bool _ok(int c) => c >= 200 && c < 300;

  // ════════════════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<String>> sendOtp(String email) async {
    try {
      final r = await http
          .post(Uri.parse(C.sendOtp),
              headers: _pub, body: jsonEncode({'email': email}))
          .timeout(_timeout);
      if (_ok(r.statusCode)) return ApiResponse.success('OTP sent');
      final b = _json(r);
      return ApiResponse.failure(
          b is Map ? b['message']?.toString() ?? 'Failed' : 'Failed');
    } catch (_) {
      return ApiResponse.failure('Network error. Check your connection.');
    }
  }

  static Future<ApiResponse<String>> verifyOtp(String email, String otp) async {
    try {
      final r = await http
          .post(Uri.parse(C.verifyOtp),
              headers: _pub, body: jsonEncode({'email': email, 'otp': otp}))
          .timeout(_timeout);

      if (!_ok(r.statusCode)) {
        final b = _json(r);
        return ApiResponse.failure(b is Map
            ? b['message']?.toString() ?? 'Invalid OTP'
            : 'Invalid OTP');
      }

      final root = _json(r);
      if (root is! Map) return ApiResponse.failure('Unexpected response');

      final data = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : Map<String, dynamic>.from(root as Map);
      final token =
          (data['accessToken'] ?? data['token'] ?? root['accessToken'])
              ?.toString();
      final userRaw = data['user'];
      final user =
          userRaw is Map ? Map<String, dynamic>.from(userRaw as Map) : null;
      final restRaw = user?['restaurant'];
      final rId = (user?['restaurantId'] ??
              (restRaw is Map ? (restRaw as Map)['id'] : null))
          ?.toString();
      final restaurantName =
          restRaw is Map ? (restRaw as Map)['name']?.toString() : null;

      if (token != null && token.isNotEmpty && rId != null && rId.isNotEmpty) {
        await _saveSession(token, rId, name: restaurantName);
        return ApiResponse.success('ok');
      }
      return ApiResponse.failure('Missing token or restaurant ID');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TABLES
  // Bug fix #1: table status comes from API — only show occupied if API says so
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<TableModel>>> getTables() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final r = await http
          .get(Uri.parse(C.tables(rId)), headers: await _auth())
          .timeout(_timeout);
      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');
      if (_ok(r.statusCode)) {
        final tables = _list(_json(r))
            .whereType<Map<String, dynamic>>()
            .map(TableModel.fromJson)
            .toList();
        return ApiResponse.success(tables);
      }
      return ApiResponse.failure('Failed to load tables (${r.statusCode})');
    } catch (_) {
      return ApiResponse.failure('Network error.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // SESSIONS
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<SessionModel>>> getSessions(
      String tableId) async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final url = '${C.sessions(rId)}?tableId=$tableId&status=OPEN&limit=50';
      debugPrint('getSessions: $url');
      final r = await http
          .get(Uri.parse(url), headers: await _auth())
          .timeout(_timeout);
      debugPrint('getSessions ${r.statusCode}');
      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');
      if (_ok(r.statusCode)) {
        final sessions = _list(_json(r))
            .whereType<Map<String, dynamic>>()
            .map(SessionModel.fromJson)
            .where((s) => s.isOpen) // extra safety filter
            .toList();
        return ApiResponse.success(sessions);
      }
      return ApiResponse.failure('Failed to load sessions (${r.statusCode})');
    } catch (_) {
      return ApiResponse.failure('Network error.');
    }
  }

  static Future<ApiResponse<OrderModel>> getSessionDetail(
      String sessionId) async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final r = await http
          .get(Uri.parse(C.session(rId, sessionId)), headers: await _auth())
          .timeout(_timeout);
      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');
      if (_ok(r.statusCode)) {
        final body = _json(r);
        final data = body is Map && body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : (body is Map<String, dynamic> ? body : null);
        if (data != null) return ApiResponse.success(OrderModel.fromJson(data));
      }
      return ApiResponse.failure('Failed to load order (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  static Future<ApiResponse<SessionModel>> createSession({
    required String tableId,
    int guestCount = 1,
    String? customerName,
  }) async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final body = <String, dynamic>{
        'tableId': tableId,
        'guestCount': guestCount,
        'channel': 'DINE_IN',
        if (customerName != null && customerName.isNotEmpty)
          'customerName': customerName,
      };
      final r = await http
          .post(Uri.parse(C.sessions(rId)),
              headers: await _auth(), body: jsonEncode(body))
          .timeout(_timeout);
      debugPrint('createSession ${r.statusCode}: ${r.body}');
      if (_ok(r.statusCode)) {
        final resp = _json(r);
        final data = resp is Map && resp['data'] is Map<String, dynamic>
            ? resp['data'] as Map<String, dynamic>
            : null;
        if (data != null)
          return ApiResponse.success(SessionModel.fromJson(data));
      }
      final b = _json(r);
      return ApiResponse.failure(
          b is Map ? b['message']?.toString() ?? 'Failed' : 'Failed');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // BATCH — add items to session
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> addBatchToSession(
      String sessionId, List<Map<String, dynamic>> items) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final r = await http
          .post(Uri.parse(C.batches(rId, sessionId)),
              headers: await _auth(), body: jsonEncode({'items': items}))
          .timeout(_timeout);
      debugPrint('addBatch ${r.statusCode}: ${r.body}');
      return _ok(r.statusCode);
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // UPDATE ITEM STATUS
  // Bug fix #2: log full URL and response to debug failures
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> updateItemStatus(
      String sessionId, String batchId, String itemId, String status) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final url = C.itemStatus(rId, sessionId, batchId, itemId);
      debugPrint('PATCH $url');
      debugPrint('body: {"status":"$status"}');
      final r = await http
          .patch(Uri.parse(url),
              headers: await _auth(), body: jsonEncode({'status': status}))
          .timeout(_timeout);
      debugPrint('response: ${r.statusCode} ${r.body}');
      return _ok(r.statusCode);
    } catch (e) {
      debugPrint('updateItemStatus error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // MENU — GET /api/v1/restaurants/{rId}/menu
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<MenuItem>>> getMenuItems() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    final h = await _auth();
    final url =
        'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/menu?fetchAll=true';
    try {
      final r = await http.get(Uri.parse(url), headers: h).timeout(_timeout);
      debugPrint('getMenuItems ${r.statusCode}');
      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');
      if (_ok(r.statusCode)) {
        final decoded = _json(r);
        List<dynamic> raw = [];
        if (decoded is Map) {
          final d = decoded['data'];
          if (d is List)
            raw = d;
          else if (d is Map) {
            for (final k in ['items', 'menuItems', 'results']) {
              if (d[k] is List) {
                raw = d[k] as List;
                break;
              }
            }
          }
          if (raw.isEmpty) {
            for (final k in ['items', 'menuItems', 'results']) {
              if (decoded[k] is List) {
                raw = decoded[k] as List;
                break;
              }
            }
          }
        } else if (decoded is List) {
          raw = decoded;
        }
        debugPrint('menu items: ${raw.length}');
        if (raw.isNotEmpty) {
          return ApiResponse.success(raw
              .whereType<Map<String, dynamic>>()
              .map(MenuItem.fromJson)
              .toList());
        }
        return ApiResponse.failure('No menu items found');
      }
      return ApiResponse.failure('Failed to load menu (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }
}
