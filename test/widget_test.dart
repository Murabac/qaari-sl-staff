import 'package:flutter_test/flutter_test.dart';
import 'package:qaari_sl_staff/core/constants/app_constants.dart';

void main() {
  test('staff API prefix is /api/staff', () {
    expect(AppConstants.apiPrefix, '/api/staff');
    expect(AppConstants.appName, 'Qaari SL Staff');
  });
}
