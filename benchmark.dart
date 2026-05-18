import 'dart:async';

// Mock Network Latency
Future<void> mockDelay() => Future.delayed(const Duration(milliseconds: 50));

// Mock N+1 Approach
Future<List<Map<String, dynamic>>> nPlusOne(List<String> worldIds) async {
  final allMembers = <Map<String, dynamic>>[];
  for (final id in worldIds) {
    await mockDelay();
    allMembers.add({'world_id': id, 'resident_id': 'res_$id'});
  }
  return allMembers;
}

// Mock Batch Approach
Future<List<Map<String, dynamic>>> batch(List<String> worldIds) async {
  await mockDelay();
  return worldIds.map((id) => {'world_id': id, 'resident_id': 'res_$id'}).toList();
}

void main() async {
  final worldIds = List.generate(20, (i) => 'world_$i');

  print("Benchmarking N+1 Query (20 worlds)...");
  final sw1 = Stopwatch()..start();
  await nPlusOne(worldIds);
  sw1.stop();
  print("N+1 Time: ${sw1.elapsedMilliseconds} ms");

  print("\nBenchmarking Batch Query (20 worlds)...");
  final sw2 = Stopwatch()..start();
  await batch(worldIds);
  sw2.stop();
  print("Batch Time: ${sw2.elapsedMilliseconds} ms");
}
