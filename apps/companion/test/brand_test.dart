// The product's name in one place on each side (plan 3.9.0, N1): the app's lib/brand.dart says
// what the protocol's brand.ts says.
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/brand.dart';

import 'repo_files.dart';

const _brand = 'packages/protocol/src/brand.ts';

void main() {
  test('the name is Rasgeth, the app alone on a computer is Rasgeth App', () {
    expect(kProductName, 'Rasgeth');
    expect(kDesktopAppName, 'Rasgeth App');
  });

  test('the same names as the protocol', skip: repoSkip(_brand), () {
    final ts = repoFile(_brand)!.readAsStringSync();
    expect(ts, contains('export const PRODUCT_NAME = "$kProductName";'));
    expect(ts, contains(r'export const DESKTOP_APP_NAME = `${PRODUCT_NAME} App`;'));
  });
}
