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
  final String log;
  ApiResponse.success(this.data, {this.log = ''})
      : ok = true,
        error = null;
  ApiResponse.failure(this.error, {this.log = ''})
      : ok = false,
        data = null;
}

class ApiService {
  static String? _token;
  static String? _restaurantId;
  static const _timeout = Duration(seconds: 15);

  // ── Session ──────────────────────────────────────────────────────────────

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

  static Future<void> _saveSession(String token, String rId) async {
    _token = token;
    _restaurantId = rId;
    final p = await SharedPreferences.getInstance();
    await p.setString(C.tokenKey, token);
    await p.setString(C.restaurantKey, rId);
  }

  static Future<void> clearToken() async {
    _token = null;
    _restaurantId = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(C.tokenKey);
    await p.remove(C.restaurantKey);
  }

  // ── Headers ──────────────────────────────────────────────────────────────

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

  // ── Helpers ──────────────────────────────────────────────────────────────

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
      for (final k in ['data', 'items', 'results', 'sessions', 'records']) {
        if (d[k] is List) return d[k] as List<dynamic>;
      }
    }
    return [];
  }

  static bool _ok(int c) => c >= 200 && c < 300;

  // ════════════════════════════════════════════════════════════════════════
  // AUTH
  // Response: { "data": { "accessToken": "...", "user": { "restaurantId": "..." } } }
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

      debugPrint('token=${token != null} rId=$rId');

      if (token != null && token.isNotEmpty && rId != null && rId.isNotEmpty) {
        await _saveSession(token, rId);
        return ApiResponse.success('ok');
      }
      return ApiResponse.failure(
          'Missing token or restaurant ID. Keys: ${data.keys.toList()}');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TABLES
  // GET /api/v1/restaurants/{rId}/tables?fetchAll=true
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<TableModel>>> getTables() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final r = await http
          .get(Uri.parse(C.tables(rId)), headers: await _auth())
          .timeout(_timeout);
      debugPrint('getTables ${r.statusCode}');
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
  // SESSIONS (ORDERS)
  // GET /api/v1/orders/restaurants/{rId}/sessions
  // GET /api/v1/orders/restaurants/{rId}/sessions/{sessionId}
  // ════════════════════════════════════════════════════════════════════════

  // Get active session for a specific table
  static Future<ApiResponse<OrderModel>> getOrder(String tableId) async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');

    final h = await _auth();

    try {
      // List all sessions and filter by tableId
      final url = '${C.sessions(rId)}?tableId=$tableId&status=OPEN';
      debugPrint('getOrder: $url');
      final r = await http.get(Uri.parse(url), headers: h).timeout(_timeout);
      debugPrint('getOrder status: ${r.statusCode}');
      debugPrint(
          'getOrder body: ${r.body.substring(0, r.body.length.clamp(0, 500))}');

      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');

      if (_ok(r.statusCode)) {
        final list = _list(_json(r));
        if (list.isNotEmpty) {
          // Get full session details (includes batches and items)
          final sessionId = (list.first as Map)['id']?.toString() ?? '';
          if (sessionId.isNotEmpty) {
            return await _getSessionDetail(rId, sessionId, h);
          }
        }
        // Try without status filter
        final r2 = await http
            .get(Uri.parse(C.sessions(rId)), headers: h)
            .timeout(_timeout);
        final list2 = _list(_json(r2));
        for (final s in list2) {
          if (s is! Map) continue;
          final tId = (s['tableId'] ?? s['table']?['id'] ?? '').toString();
          final status = (s['status'] ?? '').toString().toUpperCase();
          if (tId == tableId && (status == 'OPEN' || status == 'ACTIVE')) {
            final sessionId = s['id']?.toString() ?? '';
            if (sessionId.isNotEmpty)
              return await _getSessionDetail(rId, sessionId, h);
          }
        }
        return ApiResponse.success(null);
      }
      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('getOrder error: $e');
      return ApiResponse.failure('Network error.');
    }
  }

  // Get full session detail with all batches and items
  static Future<ApiResponse<OrderModel>> _getSessionDetail(
      String rId, String sessionId, Map<String, String> h) async {
    try {
      final url = C.session(rId, sessionId);
      debugPrint('getSessionDetail: $url');
      final r = await http.get(Uri.parse(url), headers: h).timeout(_timeout);
      debugPrint('getSessionDetail status: ${r.statusCode}');
      debugPrint(
          'getSessionDetail body: ${r.body.substring(0, r.body.length.clamp(0, 800))}');

      if (_ok(r.statusCode)) {
        final body = _json(r);
        Map<String, dynamic>? data;
        if (body is Map<String, dynamic>) {
          data = body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body;
        }
        if (data != null) {
          return ApiResponse.success(OrderModel.fromJson(data));
        }
      }
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // UPDATE ITEM STATUS
  // PATCH /api/v1/orders/restaurants/{rId}/sessions/{sId}/batches/{bId}/items/{iId}/status
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> updateItemStatus(
      String sessionId, String itemId, String status,
      {String batchId = ''}) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final url = C.itemStatus(rId, sessionId, batchId, itemId);
      final r = await http
          .patch(Uri.parse(url),
              headers: await _auth(), body: jsonEncode({'status': status}))
          .timeout(_timeout);
      return _ok(r.statusCode);
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ADD ITEMS TO SESSION (batch)
  // POST /api/v1/orders/restaurants/{rId}/sessions/{sId}/batches
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> addToOrder(String sessionId, String menuItemId, int qty,
      {String? notes}) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      // Add as a new batch with one item
      final body = {
        'items': [
          {
            'menuItemId': menuItemId,
            'quantity': qty,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          }
        ]
      };
      final r = await http
          .post(Uri.parse(C.batches(rId, sessionId)),
              headers: await _auth(), body: jsonEncode(body))
          .timeout(_timeout);
      debugPrint('addToOrder ${r.statusCode}: ${r.body}');
      return _ok(r.statusCode);
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // MENU ITEMS
  // GET /api/v1/restaurants/{rId}/menu
  // ════════════════════════════════════════════════════════════════════════

  static Future<ApiResponse<List<MenuItem>>> getMenuItems() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    try {
      final r = await http
          .get(Uri.parse(C.menu(rId)), headers: await _auth())
          .timeout(_timeout);
      debugPrint('getMenuItems ${r.statusCode}');
      if (r.statusCode == 401)
        return ApiResponse.failure('Session expired. Please log in again.');
      if (_ok(r.statusCode)) {
        final items = _list(_json(r))
            .whereType<Map<String, dynamic>>()
            .map(MenuItem.fromJson)
            .toList();
        return ApiResponse.success(items);
      }
      return ApiResponse.failure('Failed to load menu (${r.statusCode})');
    } catch (_) {
      return ApiResponse.failure('Network error.');
    }
  }
}
