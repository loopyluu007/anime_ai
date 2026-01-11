import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

/// SEO工具类
/// 提供搜索引擎优化相关功能
class SEOUtils {
  /// 设置页面标题
  static void setTitle(String title) {
    if (!kIsWeb) return;
    html.document.title = title;
  }

  /// 获取页面标题
  static String getTitle() {
    if (!kIsWeb) return '';
    return html.document.title;
  }

  /// 设置Meta描述
  static void setMetaDescription(String description) {
    if (!kIsWeb) return;

    var meta = html.document.querySelector('meta[name="description"]') as html.MetaElement?;
    if (meta != null) {
      meta.content = description;
    } else {
      meta = html.MetaElement()
        ..name = 'description'
        ..content = description;
      html.document.head?.append(meta);
    }
  }

  /// 设置Meta关键词
  static void setMetaKeywords(String keywords) {
    if (!kIsWeb) return;

    var meta = html.document.querySelector('meta[name="keywords"]') as html.MetaElement?;
    if (meta != null) {
      meta.content = keywords;
    } else {
      meta = html.MetaElement()
        ..name = 'keywords'
        ..content = keywords;
      html.document.head?.append(meta);
    }
  }

  /// 设置Open Graph标签
  static void setOpenGraph({
    String? title,
    String? description,
    String? image,
    String? url,
    String? type,
  }) {
    if (!kIsWeb) return;

    if (title != null) {
      _setMetaProperty('og:title', title);
    }
    if (description != null) {
      _setMetaProperty('og:description', description);
    }
    if (image != null) {
      _setMetaProperty('og:image', image);
    }
    if (url != null) {
      _setMetaProperty('og:url', url);
    }
    if (type != null) {
      _setMetaProperty('og:type', type);
    }
  }

  /// 设置Twitter Card标签
  static void setTwitterCard({
    String? card,
    String? title,
    String? description,
    String? image,
  }) {
    if (!kIsWeb) return;

    if (card != null) {
      _setMetaProperty('twitter:card', card);
    }
    if (title != null) {
      _setMetaProperty('twitter:title', title);
    }
    if (description != null) {
      _setMetaProperty('twitter:description', description);
    }
    if (image != null) {
      _setMetaProperty('twitter:image', image);
    }
  }

  /// 设置Canonical URL
  static void setCanonicalUrl(String url) {
    if (!kIsWeb) return;

    var link = html.document.querySelector('link[rel="canonical"]') as html.LinkElement?;
    if (link != null) {
      link.href = url;
    } else {
      link = html.LinkElement()
        ..rel = 'canonical'
        ..href = url;
      html.document.head?.append(link);
    }
  }

  /// 设置Meta属性（私有方法）
  static void _setMetaProperty(String property, String content) {
    var meta = html.document.querySelector('meta[property="$property"]') as html.MetaElement?;
    if (meta != null) {
      meta.content = content;
    } else {
      meta = html.MetaElement()
        ..setAttribute('property', property)
        ..content = content;
      html.document.head?.append(meta);
    }
  }

  /// 设置结构化数据（JSON-LD）
  static void setStructuredData(Map<String, dynamic> data) {
    if (!kIsWeb) return;

    // 移除旧的structured data
    final oldScript = html.document.querySelector('script[type="application/ld+json"]');
    if (oldScript != null) {
      oldScript.remove();
    }

    // 添加新的structured data
    final script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..text = data.toString(); // 实际应该使用jsonEncode
    html.document.head?.append(script);
  }

  /// 更新页面URL（不刷新页面）
  static void updateUrl(String url, {String? title}) {
    if (!kIsWeb) return;

    html.window.history.pushState(null, title ?? '', url);
  }

  /// 设置favicon
  static void setFavicon(String iconUrl) {
    if (!kIsWeb) return;

    var link = html.document.querySelector('link[rel="icon"]') as html.LinkElement?;
    if (link != null) {
      link.href = iconUrl;
    } else {
      link = html.LinkElement()
        ..rel = 'icon'
        ..href = iconUrl;
      html.document.head?.append(link);
    }
  }
}
