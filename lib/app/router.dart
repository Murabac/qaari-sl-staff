import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qaari_sl_staff/core/auth/auth_controller.dart';
import 'package:qaari_sl_staff/features/account/account_screen.dart';
import 'package:qaari_sl_staff/features/auth/login_screen.dart';
import 'package:qaari_sl_staff/features/home/dashboard_screen.dart';
import 'package:qaari_sl_staff/features/home/home_shell.dart';
import 'package:qaari_sl_staff/features/recitations/upload_screen.dart';
import 'package:qaari_sl_staff/features/reciters/reciter_detail_screen.dart';
import 'package:qaari_sl_staff/features/reciters/reciter_form_screen.dart';
import 'package:qaari_sl_staff/features/reciters/reciters_screen.dart';
import 'package:qaari_sl_staff/features/reviews/review_detail_screen.dart';
import 'package:qaari_sl_staff/features/reviews/reviews_screen.dart';
import 'package:qaari_sl_staff/features/sync/ayah_sync_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final atSplash = state.matchedLocation == '/splash';
      final loggingIn = state.matchedLocation == '/login';
      if (auth.status == AuthStatus.unknown) {
        return atSplash ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn || atSplash) {
        return '/home';
      }
      final isReviewer = auth.user?.isReviewer ?? false;
      if (!isReviewer &&
          (state.matchedLocation.startsWith('/reviews') ||
              state.matchedLocation.startsWith('/sync'))) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/sync/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AyahSyncScreen(recitationId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reciters',
                builder: (context, state) => const RecitersScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ReciterFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ReciterDetailScreen(reciterId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return ReciterFormScreen(reciterId: id);
                        },
                      ),
                      GoRoute(
                        path: 'upload',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          final replaceId = int.tryParse(
                            state.uri.queryParameters['replace'] ?? '',
                          );
                          return UploadScreen(
                            reciterId: id,
                            replaceRecitationId: replaceId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reviews',
                builder: (context, state) => const ReviewsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ReviewDetailScreen(recitationId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
