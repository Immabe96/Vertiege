import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/image_cache_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('apply sets image cache limits', () {
    ImageCachePolicy.apply();
    final cache = PaintingBinding.instance.imageCache;
    expect(cache.maximumSize, ImageCachePolicy.maxImages);
    expect(cache.maximumSizeBytes, ImageCachePolicy.maxBytes);
  });
}
