import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:universal_html/html.dart' as html;

/// Tắt pointer events trên tất cả các thẻ <iframe> trong DOM để Flutter nhận toàn bộ tương tác
void disableIframesPointerEvents() {
  if (kIsWeb) {
    try {
      html.document.querySelectorAll('iframe').forEach((el) {
        (el as html.IFrameElement).style.pointerEvents = 'none';
      });
    } catch (_) {}
  }
}

/// Khôi phục lại pointer events trên các thẻ <iframe> khi đóng Dialog
void enableIframesPointerEvents() {
  if (kIsWeb) {
    try {
      html.document.querySelectorAll('iframe').forEach((el) {
        (el as html.IFrameElement).style.pointerEvents = 'auto';
      });
    } catch (_) {}
  }
}

/// Hàm mở Dialog dùng chung toàn ứng dụng, tự động tắt tương tác thẻ <iframe>
/// và bọc bằng [PointerInterceptor] để giải quyết triệt để lỗi mất tương tác chuột trên Web.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) async {
  disableIframesPointerEvents();
  try {
    return await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (BuildContext ctx) {
        return PointerInterceptor(child: builder(ctx));
      },
    );
  } finally {
    enableIframesPointerEvents();
  }
}
