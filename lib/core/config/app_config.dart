class AppConfig {
  static bool _initialized = false;
  static bool debug = false;
  
  static Future<void> init({bool debugMode = false}) async {
    if (_initialized) return;
    
    debug = debugMode;
    _initialized = true;
  }
}
