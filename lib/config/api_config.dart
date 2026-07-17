/// Central place for the backend API URL.
///
/// IMPORTANT: since the backend runs via ngrok through a Colab notebook,
/// this URL changes every time the server is restarted. Update it here
/// each session before testing.
class ApiConfig {
  static const String baseUrl = "https://overpower-passably-chug.ngrok-free.dev";

  static String get predictEndpoint => "$baseUrl/predict";
  static String get predictMultiEndpoint => "$baseUrl/predict_multi";
  static String get healthEndpoint => "$baseUrl/health";
}