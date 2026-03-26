class endPoint {
  static const _base = 'https://api.pos.palqar.cloud/api/v1';
  static const _orders = 'https://api.pos.palqar.cloud/api/v1/orders';
  static const tokenKey = 'auth_token';
  static const restaurantKey = 'restaurant_id';

  // Auth
  static const sendOtp = '$_base/auth/send-otp';
  static const verifyOtp = '$_base/auth/verify-otp';

  // Tables
  static String tables(String rId) =>
      '$_base/restaurants/$rId/tables?fetchAll=true';

  // Sessions (Orders)
  static String sessions(String rId) => '$_orders/restaurants/$rId/sessions';
  static String session(String rId, String sId) =>
      '$_orders/restaurants/$rId/sessions/$sId';
  static String batches(String rId, String sId) =>
      '$_orders/restaurants/$rId/sessions/$sId/batches';

  // Item status update
  static String itemStatus(String rId, String sId, String bId, String iId) =>
      '$_orders/restaurants/$rId/sessions/$sId/batches/$bId/items/$iId/status';

  // Menu — confirmed endpoint from Swagger: /menu-items with fetchAll
  static String menu(String rId) =>
      '$_base/restaurants/$rId/menu-items?fetchAll=true';
}
