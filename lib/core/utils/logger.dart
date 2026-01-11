import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class Logger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode || AppConfig.debug) {
      print('[DEBUG] $message');
      if (error != null) {
        print('[ERROR] $error');
      }
      if (stackTrace != null) {
        print('[STACK] $stackTrace');
      }
    }
  }
  
  static void info(String message) {
    if (kDebugMode || AppConfig.debug) {
      print('[INFO] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode || AppConfig.debug) {
      print('[WARNING] $message');
    }
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode || AppConfig.debug) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR DETAIL] $error');
      }
      if (stackTrace != null) {
        print('[STACK] $stackTrace');
      }
    }
  }
}
