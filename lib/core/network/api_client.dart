import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qaari_sl_staff/core/auth/token_store.dart';
import 'package:qaari_sl_staff/core/constants/app_constants.dart';

final sessionInvalidatedProvider = StateProvider<int>((ref) => 0);

final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  return createApiClient(
    tokenStore: store,
    onUnauthorized: () {
      ref.read(sessionInvalidatedProvider.notifier).state++;
    },
  );
});

Dio createApiClient({
  String? baseUrl,
  TokenStore? tokenStore,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${baseUrl ?? AppConstants.apiBaseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore?.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore?.clear();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
