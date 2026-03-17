class ApiConstants {
  static const baseUrl = "https://api.pos.palqar.cloud/api/v1";

  static const sendOtp = "$baseUrl/auth/send-otp";
  static const verifyOtp = "$baseUrl/auth/verify-otp";

  static String tables(String restaurantId) =>
      "$baseUrl/restaurants/$restaurantId/tables";

  static String cart(String restaurantId) =>
      "$baseUrl/restaurants/$restaurantId/cart";
}
