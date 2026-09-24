import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void safeBack(BuildContext context, {String fallback = '/'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
