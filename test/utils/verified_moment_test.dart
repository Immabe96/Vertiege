import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/post.dart';
import 'package:vertiege/utils/verified_moment.dart';

void main() {
  test('isVerifiedMomentPost detects nexus world and hashtag', () {
    const nexusPost = Post(
      id: '1',
      worldId: 'nexus',
      residentId: 'r1',
      residentName: 'A',
      residentAvatar: '',
      content: 'Hello',
      timestamp: 0,
    );
    expect(isVerifiedMomentPost(nexusPost), isTrue);

    const tagged = Post(
      id: '2',
      worldId: 'world-a',
      residentId: 'r1',
      residentName: 'A',
      residentAvatar: '',
      content: 'Just verified: Degree $verifiedMomentHashtag',
      timestamp: 0,
    );
    expect(isVerifiedMomentPost(tagged), isTrue);

    const plain = Post(
      id: '3',
      worldId: 'world-a',
      residentId: 'r1',
      residentName: 'A',
      residentAvatar: '',
      content: 'Random update',
      timestamp: 0,
    );
    expect(isVerifiedMomentPost(plain), isFalse);
  });

  test('verifiedMomentDraft includes hashtag', () {
    final draft = verifiedMomentDraft('Elite tier');
    expect(draft, contains('Just verified: Elite tier'));
    expect(draft, contains(verifiedMomentHashtag));
  });
}
