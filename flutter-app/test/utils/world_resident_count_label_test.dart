import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/world_resident_count_label.dart';

void main() {
  test('worldChannelResidentSubtitle formats online and total', () {
    expect(
      worldChannelResidentSubtitle(totalResidents: 42, onlineResidents: 7),
      '7 online · 42 residents',
    );
    expect(
      worldChannelResidentSubtitle(totalResidents: 1, onlineResidents: 1),
      '1 online · 1 resident',
    );
    expect(
      worldChannelResidentSubtitle(totalResidents: 5),
      '5 residents',
    );
    expect(worldChannelResidentSubtitle(totalResidents: 0), '');
  });
}
