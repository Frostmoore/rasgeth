// Golden files are made on Linux (the CI's check job, ubuntu): there they must match exactly.
// Other systems rasterise a few edge pixels differently (macOS: 2 pixels, 0.01%, on one mascot),
// so on Windows and macOS a difference of at most 0.05% of the pixels is accepted.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const double kGoldenToleranceElsewhere = 0.0005;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!Platform.isLinux && goldenFileComparator is LocalFileComparator) {
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(
      current.basedir.resolve('flutter_test_config.dart'),
      kGoldenToleranceElsewhere,
    );
  }
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile, this.tolerance);

  /// Share of pixels (0-1) that may differ.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
