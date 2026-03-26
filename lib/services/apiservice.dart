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
    _token =
        (await SharedPreferences.getInstance()).getString(endPoint.tokenKey);
    return _token;
  }

  static Future<String?> getRestaurantId() async {
    if (_restaurantId != null) return _restaurantId;
    _restaurantId = (await SharedPreferences.getInstance())
        .getString(endPoint.restaurantKey);
    return _restaurantId;
  }

  static Future<void> _saveSession(String token, String rId) async {
    _token = token;
    _restaurantId = rId;
    final p = await SharedPreferences.getInstance();
    await p.setString(endPoint.tokenKey, token);
    await p.setString(endPoint.restaurantKey, rId);
  }

  static Future<void> clearToken() async {
    _token = null;
    _restaurantId = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(endPoint.tokenKey);
    await p.remove(endPoint.restaurantKey);
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
          .post(Uri.parse(endPoint.sendOtp),
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
          .post(Uri.parse(endPoint.verifyOtp),
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

      if (token != null && token.isNotEmpty && rId != null && rId.isNotEmpty) {
        await _saveSession(token, rId);
        return ApiResponse.success('ok');
      }
      return ApiResponse.failure('Missing token or restaurant ID');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TABLES
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<TableModel>>> getTables() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final r = await http
          .get(Uri.parse(endPoint.tables(rId)), headers: await _auth())
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
  // GET /api/v1/orders/restaurants/{rId}/sessions?tableId=x
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<SessionModel>>> getSessions(
      String tableId) async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final url =
          '${endPoint.sessions(rId)}?tableId=$tableId&limit=50&status=OPEN';
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
            .toList();
        return ApiResponse.success(sessions);
      }
      return ApiResponse.failure('Failed to load sessions (${r.statusCode})');
    } catch (_) {
      return ApiResponse.failure('Network error.');
    }
  }

  // GET /api/v1/orders/restaurants/{rId}/sessions/{sessionId}
  static Future<ApiResponse<OrderModel>> getSessionDetail(
      String sessionId) async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final url = endPoint.session(rId, sessionId);
      debugPrint('getSessionDetail: $url');
      final r = await http
          .get(Uri.parse(url), headers: await _auth())
          .timeout(_timeout);
      debugPrint(
          'getSessionDetail ${r.statusCode}: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
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

  // POST /api/v1/orders/restaurants/{rId}/sessions
  // Body: { tableId, guestCount, customerName, channel }
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
          .post(Uri.parse(endPoint.sessions(rId)),
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
  // ADD ITEMS TO SESSION (new batch)
  // POST /api/v1/orders/restaurants/{rId}/sessions/{sessionId}/batches
  // Body: { items: [{ menuItemId, quantity, notes }] }
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> addBatchToSession(
      String sessionId, List<Map<String, dynamic>> items) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final body = {'items': items};
      final r = await http
          .post(Uri.parse(endPoint.batches(rId, sessionId)),
              headers: await _auth(), body: jsonEncode(body))
          .timeout(_timeout);
      debugPrint('addBatch ${r.statusCode}: ${r.body}');
      return _ok(r.statusCode);
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // UPDATE ITEM STATUS
  // PATCH /api/v1/orders/restaurants/{rId}/sessions/{sId}/batches/{bId}/items/{iId}/status
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> updateItemStatus(
      String sessionId, String batchId, String itemId, String status) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final r = await http
          .patch(
              Uri.parse(endPoint.itemStatus(rId, sessionId, batchId, itemId)),
              headers: await _auth(),
              body: jsonEncode({'status': status}))
          .timeout(_timeout);
      return _ok(r.statusCode);
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // MENU
  // GET /api/v1/restaurants/{rId}/menu
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<MenuItem>>> getMenuItems() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');

    final h = await _auth();
    final url =
        'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/menu?fetchAll=true';

    try {
      debugPrint('Loading menu: $url');
      final r = await http.get(Uri.parse(url), headers: h).timeout(_timeout);
      debugPrint('Menu status: ${r.statusCode}');
      debugPrint(
          'Menu body (first 600): ${r.body.substring(0, r.body.length.clamp(0, 600))}');

      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');

      if (_ok(r.statusCode)) {
        final decoded = _json(r);

        // The API wraps in { data: [...] }
        List<dynamic> raw = [];
        if (decoded is Map) {
          final d = decoded['data'];
          if (d is List) {
            raw = d;
          } else if (d is Map) {
            // Sometimes nested: { data: { items: [...] } }
            for (final k in ['items', 'menuItems', 'data', 'results']) {
              if (d[k] is List) {
                raw = d[k] as List;
                break;
              }
            }
          }
          // Also try top-level list keys
          if (raw.isEmpty) {
            for (final k in ['items', 'menuItems', 'results', 'data']) {
              if (decoded[k] is List) {
                raw = decoded[k] as List;
                break;
              }
            }
          }
        } else if (decoded is List) {
          raw = decoded;
        }

        debugPrint('Menu items parsed: ${raw.length}');

        if (raw.isNotEmpty) {
          final items = raw
              .whereType<Map<String, dynamic>>()
              .map(MenuItem.fromJson)
              .toList();
          return ApiResponse.success(items);
        }

        // 200 but empty — log the full body for debugging
        debugPrint('FULL MENU BODY: ${r.body}');
        return ApiResponse.failure(
            'Menu loaded but no items found. Body: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
      }
      return ApiResponse.failure('Failed to load menu (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }
}
