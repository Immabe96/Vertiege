import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertiege/services/last_channel_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load last channel per world', () async {
    await LastChannelPrefs.save(worldId: 'w1', channelId: 'c1');
    expect(await LastChannelPrefs.loadForWorld('w1'), 'c1');
    expect(await LastChannelPrefs.loadForWorld('w2'), isNull);
  });

  test('overwrites previous channel for same world', () async {
    await LastChannelPrefs.save(worldId: 'w1', channelId: 'c1');
    await LastChannelPrefs.save(worldId: 'w1', channelId: 'c2');
    expect(await LastChannelPrefs.loadForWorld('w1'), 'c2');
  });
}
