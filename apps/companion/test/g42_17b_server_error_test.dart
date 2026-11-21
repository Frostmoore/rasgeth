import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live_model.dart';

// G42.17b: the server's error on the live link reaches the person, as the page's lastError.
void main() {
  test("the server's error becomes a notice; the browser's unavailable does not", () {
    final live = LiveModel();
    live.apply({'type': 'error', 'code': 'unavailable', 'message': 'no browser here'});
    expect(live.serverError.value, isNull);
    live.apply({'type': 'error', 'code': 'no_model', 'message': ' No model is set. '});
    expect(live.serverError.value, 'No model is set.');
  });
}
