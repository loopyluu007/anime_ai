// Stub file for dart:html when not on web platform
// This file provides empty implementations to satisfy the type system

library html_stub;

/// Stub for Window
class Window {
  Navigator? navigator;
}

/// Stub for Navigator  
class Navigator {
  Future<void> Function(Map<String, String>)? share;
}

/// Stub for html library - provides window property
class _HtmlStub {
  final Window window = Window();
}

/// Stub html object - actual implementations will never be called on non-web platforms
final _HtmlStub html = _HtmlStub();
