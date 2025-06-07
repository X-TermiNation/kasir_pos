import 'dart:async';
import 'package:http/http.dart' as http;

class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;

  ApiConfig._internal();

  final String _localUrl = "http://10.0.2.2:3000";
  final String _railwayUrl = "https://serverpos-production.up.railway.app";

  String _baseUrl = "http://10.0.2.2:3000";
  String get baseUrl => _baseUrl;

  bool _initialized = false;
  Timer? _timer;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _checkInternetAndSwitch();
    _startPeriodicCheck();
  }

  Future<void> _checkInternetAndSwitch() async {
    try {
      final response = await http
          .get(Uri.parse("$_railwayUrl/user/ping"))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        _baseUrl = _railwayUrl;
        print("[ApiConfig] Railway available, using hosting URL.");
      } else {
        _baseUrl = _localUrl;
        print("[ApiConfig] Railway unreachable, fallback to local.");
      }
    } catch (e) {
      _baseUrl = _localUrl;
      print("[ApiConfig] Internet check failed, fallback to local.");
    }
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkInternetAndSwitch();
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  bool get isReady => _initialized;
}
