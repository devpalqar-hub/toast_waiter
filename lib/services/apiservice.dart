import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savorya_staff/models/analytics.dart';
import 'package:savorya_staff/models/restuarent.dart';
import 'package:savorya_staff/models/retention.dart';
import 'package:savorya_staff/models/revnuechannel.dart';
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

  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp(
      String email, String otp) async {
    try {
      final r = await http
          .post(Uri.parse(C.verifyOtp),
              headers: _pub, body: jsonEncode({'email': email, 'otp': otp}))
          .timeout(_timeout);

      if (!_ok(r.statusCode)) {
        final b = _json(r);
        return ApiResponse.failure(
          b is Map ? b['message']?.toString() ?? 'Invalid OTP' : 'Invalid OTP',
        );
      }

      final root = _json(r);
      if (root is! Map) {
        return ApiResponse.failure('Unexpected response');
      }

      final data =
          root['data'] is Map ? Map<String, dynamic>.from(root['data']) : root;

      final token =
          (data['accessToken'] ?? data['token'] ?? root['accessToken'])
              ?.toString();

      final userRaw = data['user'];
      final user = userRaw is Map ? Map<String, dynamic>.from(userRaw) : null;

      final role = user?['role']?.toString(); // ✅ IMPORTANT

      final restRaw = user?['restaurant'];
      final rId =
          (user?['restaurantId'] ?? (restRaw is Map ? restRaw['id'] : null))
              ?.toString();

      final restaurantName =
          restRaw is Map ? restRaw['name']?.toString() : null;

      if (token != null && rId != null) {
        await _saveSession(token, rId, name: restaurantName);

        return ApiResponse.success({
          'role': role,
          'user': user,
        }); // ✅ RETURN ROLE
      }

      return ApiResponse.failure('Missing token or restaurant ID');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

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

  static Future<bool> hasOpenSession(String tableId) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final r = await http
          .get(
              Uri.parse(
                  '${C.sessions(rId)}?tableId=$tableId&status=OPEN&limit=1'),
              headers: await _auth())
          .timeout(const Duration(seconds: 5));
      if (_ok(r.statusCode)) {
        final list = _list(_json(r));
        return list.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

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
            .where((s) => s.isOpen)
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
      final url = C.session(rId, sessionId);
      final headers = await _auth();

      /// 🔹 PRINT REQUEST
      print('📤 GET REQUEST');
      print('URL: $url');
      print('Headers: $headers');
      print('Session ID: $sessionId');

      final r =
          await http.get(Uri.parse(url), headers: headers).timeout(_timeout);

      /// 🔹 PRINT RESPONSE
      print('📥 RESPONSE');
      print('Status Code: ${r.statusCode}');
      print('Body: ${r.body}');

      if (r.statusCode == 401) {
        return ApiResponse.failure('Session expired. Please log in again.');
      }

      if (_ok(r.statusCode)) {
        final body = _json(r);

        print('📦 PARSED JSON: $body');

        final data = body is Map && body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : (body is Map<String, dynamic> ? body : null);

        if (data != null) {
          print('✅ FINAL DATA: $data');
          return ApiResponse.success(OrderModel.fromJson(data));
        }
      }

      return ApiResponse.failure('Failed to load order (${r.statusCode})');
    } catch (e) {
      print('❌ ERROR: $e');
      print('❌ PARSE ERROR: $e');

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

      String errMsg = 'Failed to create session';
      if (b is Map) {
        errMsg = b['message']?.toString() ??
            b['error']?.toString() ??
            'Failed to create session';
      }
      return ApiResponse.failure(errMsg);
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

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

  static Future<bool> updateItemStatus(
      String sessionId, String batchId, String itemId, String status) async {
    final rId = await getRestaurantId();
    if (rId == null) return false;
    try {
      final url = C.itemStatus(rId, sessionId, batchId, itemId);
      debugPrint('PATCH $url');
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

  static Future<ApiResponse<List<MenuItem>>> getMenuItems() async {
    final rId = await getRestaurantId();
    if (rId == null) return ApiResponse.failure('Not logged in.');
    final h = await _auth();

    final urls = [
      'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/menu?fetchAll=true',
      'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/menu',
      'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/menu-items',
      'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/items',
    ];

    http.Response? lastResponse;
    for (final url in urls) {
      try {
        debugPrint('getMenuItems trying: $url');
        final r = await http.get(Uri.parse(url), headers: h).timeout(_timeout);
        debugPrint(
            'getMenuItems ${r.statusCode} — body preview: ${r.body.length > 300 ? r.body.substring(0, 300) : r.body}');

        if (r.statusCode == 401) {
          return ApiResponse.failure('Session expired. Please log in again.');
        }

        lastResponse = r;

        if (_ok(r.statusCode)) {
          final items = _extractMenuItems(r.body);
          if (items.isNotEmpty) {
            debugPrint('getMenuItems: found ${items.length} items from $url');
            await _applyEffectivePrices(items, rId, h);
            return ApiResponse.success(items);
          }
          debugPrint('getMenuItems: 200 but no items found, trying next URL');
        }
      } catch (e) {
        debugPrint('getMenuItems error for $url: $e');
      }
    }

    if (lastResponse != null) {
      return ApiResponse.failure(
          'Menu not available (${lastResponse.statusCode}). Please check your internet and retry.');
    }
    return ApiResponse.failure('Network error. Please check your connection.');
  }

  static List<MenuItem> _extractMenuItems(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return [];
    }

    final raw = _findItemsList(decoded);
    if (raw.isEmpty) return [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(MenuItem.fromJson)
        .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
        .toList();
  }

  static List<dynamic> _findItemsList(dynamic node, {int depth = 0}) {
    if (depth > 5) return [];

    if (node is List && node.isNotEmpty) {
      if (node.first is Map &&
          ((node.first as Map).containsKey('name') ||
              (node.first as Map).containsKey('id'))) {
        return node;
      }
    }

    if (node is Map) {
      // Try common keys first
      const priorityKeys = [
        'items',
        'menuItems',
        'data',
        'results',
        'records',
        'menu',
        'products',
        'list',
      ];
      for (final k in priorityKeys) {
        if (node.containsKey(k)) {
          final result = _findItemsList(node[k], depth: depth + 1);
          if (result.isNotEmpty) return result;
        }
      }
      for (final v in node.values) {
        final result = _findItemsList(v, depth: depth + 1);
        if (result.isNotEmpty) return result;
      }
    }

    return [];
  }

  static Future<void> _applyEffectivePrices(
      List<MenuItem> items, String rId, Map<String, String> h) async {
    const batchSize = 5;
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((item) async {
        try {
          final url =
              'https://api.pos.palqar.cloud/api/v1/restaurants/$rId/menu/${item.id}/price-rules/effective-price';
          final r = await http
              .get(Uri.parse(url), headers: h)
              .timeout(const Duration(seconds: 5));
          if (_ok(r.statusCode)) {
            final body = _json(r);
            final ep = body is Map
                ? (body['data']?['effectivePrice'] ??
                    body['effectivePrice'] ??
                    body['data']?['price'] ??
                    body['price'])
                : null;
            if (ep != null) {
              final price = double.tryParse(ep.toString());
              if (price != null && price > 0) {
                items[items.indexOf(item)] = MenuItem(
                  id: item.id,
                  name: item.name,
                  category: item.category,
                  price: item.price,
                  effectivePrice: price,
                  description: item.description,
                  imageUrl: item.imageUrl,
                );
              }
            }
          }
        } catch (_) {}
      }));
    }
  }

  static Future<ApiResponse<List<RestaurantModel>>> getRestaurants() async {
    try {
      final r = await http
          .get(Uri.parse('https://api.pos.palqar.cloud/api/v1/restaurants'),
              headers: await _auth())
          .timeout(_timeout);

      if (r.statusCode == 401) {
        return ApiResponse.failure('Session expired. Please login again');
      }

      if (_ok(r.statusCode)) {
        final body = _json(r);

        final list =
            body is Map && body['data'] is Map && body['data']['data'] is List
                ? body['data']['data'] as List
                : [];

        final restaurants = list
            .whereType<Map<String, dynamic>>()
            .map((e) => RestaurantModel.fromJson(e))
            .toList();

        return ApiResponse.success(restaurants);
      }

      return ApiResponse.failure('Failed (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  static Future<ApiResponse<AnalyticsModel>> getAovAnalytics(String rId) async {
    try {
      final url = 'https://api.pos.palqar.cloud/api/v1/analytics/aov/$rId';

      final r = await http
          .get(Uri.parse(url), headers: await _auth())
          .timeout(_timeout);

      if (r.statusCode == 401) {
        return ApiResponse.failure('Session expired');
      }

      if (_ok(r.statusCode)) {
        final body = _json(r);

        final data = body is Map && body['data'] is Map ? body['data'] : null;

        if (data != null) {
          return ApiResponse.success(AnalyticsModel.fromJson(data));
        }
      }

      return ApiResponse.failure('Failed (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  static Future<ApiResponse<RetentionModel>> getCustomerRetention(
      String rId) async {
    try {
      final url =
          'https://api.pos.palqar.cloud/api/v1/analytics/customer-retention/$rId';

      final headers = await _auth();

      final r =
          await http.get(Uri.parse(url), headers: headers).timeout(_timeout);

      if (r.statusCode == 401) {
        return ApiResponse.failure('Session expired');
      }

      if (_ok(r.statusCode)) {
        final body = _json(r);

        final data = body is Map && body['data'] is Map ? body['data'] : null;

        if (data != null) {
          return ApiResponse.success(
            RetentionModel.fromJson(data),
          );
        }
      }

      return ApiResponse.failure('Failed (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }

  static Future<ApiResponse<List<RevenueChannelModel>>> getRevenueByChannel(
      String rId) async {
    try {
      final url =
          'https://api.pos.palqar.cloud/api/v1/analytics/revenue-by-channel/$rId';

      final r = await http
          .get(Uri.parse(url), headers: await _auth())
          .timeout(_timeout);

      if (r.statusCode == 401) {
        return ApiResponse.failure('Session expired');
      }

      if (_ok(r.statusCode)) {
        final body = _json(r);

        final list =
            body is Map && body['data'] is List ? body['data'] as List : [];

        final data = list
            .whereType<Map<String, dynamic>>()
            .map((e) => RevenueChannelModel.fromJson(e))
            .toList();

        return ApiResponse.success(data);
      }

      return ApiResponse.failure('Failed (${r.statusCode})');
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }
}
