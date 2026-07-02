import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

/// Generate a globally unique ID using UUID v4.
/// This replaces the previous timestamp+random approach which was collision-prone.
String generateId() => _uuid.v4();
