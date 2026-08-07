import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qaari_sl_staff/app/router.dart';
import 'package:qaari_sl_staff/core/constants/app_constants.dart';
import 'package:qaari_sl_staff/core/theme/app_theme.dart';

class QaariSlStaffApp extends ConsumerWidget {
  const QaariSlStaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
