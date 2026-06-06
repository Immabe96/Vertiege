import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/widgets/chat/scroll_fab.dart';

void main() {
  testWidgets('ChatScrollFabTracker shows badge for new messages while away',
      (tester) async {
    final controller = ScrollController();
    final tracker = ChatScrollFabTracker();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 200,
          child: ListView.builder(
            controller: controller,
            itemCount: 20,
            itemBuilder: (_, i) => SizedBox(height: 50, child: Text('$i')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tracker.syncMessageCount(5);
    expect(tracker.show, isFalse);

    controller.jumpTo(0);
    expect(tracker.updateFromScroll(controller), isTrue);
    expect(tracker.show, isTrue);

    tracker.syncMessageCount(8);
    expect(tracker.badgeCount, 3);

    controller.jumpTo(controller.position.maxScrollExtent);
    expect(tracker.updateFromScroll(controller), isTrue);
    expect(tracker.show, isFalse);
    expect(tracker.badgeCount, 0);
  });
}
