import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kids_transport/core/network/api_endpoints.dart';

/// 🌟 ويدجت آمن موحد لعرض صور المستخدمين (الأطفال/السائقين)
/// يحمي التطبيق تماماً من استثناء EncodingError أو الصور المكسورة
class AppUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? iconSize;

  const AppUserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 22.0,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
  });

  /// هيدر مطلوب لتجاوز صفحة تحذير localtunnel (loca.lt) عند تحميل الصور
  static const Map<String, String> imageHeaders = {
    'bypass-tunnel-reminder': 'true',
  };

  /// يحوّل الروابط النسبية وروابط localhost إلى رابط كامل على السيرفر
  static String? resolveUrl(String? raw) {
    if (raw == null) return null;
    final url = raw.trim();
    if (url.isEmpty) return null;

    final serverHost = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/?api/?$'), '');
    String resolved = url;

    if (url.startsWith('http://localhost') || url.startsWith('http://127.0.0.1')) {
      final uri = Uri.parse(url);
      resolved = '$serverHost${uri.path}';
    } else if (url.startsWith('//')) {
      resolved = 'https:$url';
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final cleanPath = url.startsWith('/') ? url : '/$url';
      resolved = '$serverHost$cleanPath';
    }

    if (ApiEndpoints.baseUrl.startsWith('https://') && resolved.startsWith('http://')) {
      resolved = 'https://${resolved.substring(7)}';
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? Theme.of(context).primaryColor.withValues(alpha: 0.1);
    final effectiveIconColor = iconColor ?? Theme.of(context).primaryColor;
    final effectiveIconSize = iconSize ?? (radius * 1.0);

    final Widget fallbackWidget = CircleAvatar(
      radius: radius,
      backgroundColor: effectiveBg,
      child: Icon(
        Icons.person_rounded,
        size: effectiveIconSize,
        color: effectiveIconColor,
      ),
    );

    final resolvedUrl = resolveUrl(imageUrl);
    if (resolvedUrl == null) {
      return fallbackWidget;
    }

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      httpHeaders: imageHeaders,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: effectiveBg,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: effectiveBg,
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: effectiveIconColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => fallbackWidget,
    );
  }
}
