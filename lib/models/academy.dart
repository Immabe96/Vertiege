class AcademyCourse {
  final String id;
  final String worldId;
  final String instructorId;
  final String instructorName;
  final String title;
  final String description;
  final List<Map<String, dynamic>> syllabus;
  final String difficulty;
  final int durationWeeks;
  final int enrolledCount;
  final bool isPublished;
  final DateTime createdAt;

  const AcademyCourse({
    required this.id,
    required this.worldId,
    required this.instructorId,
    required this.instructorName,
    required this.title,
    this.description = '',
    this.syllabus = const [],
    this.difficulty = 'beginner',
    this.durationWeeks = 4,
    this.enrolledCount = 0,
    this.isPublished = false,
    required this.createdAt,
  });

  static AcademyCourse fromSupabase(Map<String, dynamic> data) => AcademyCourse(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    instructorId: data['instructor_id'] ?? '',
    instructorName: data['instructor_name'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    syllabus: data['syllabus'] is List
        ? (data['syllabus'] as List).map((e) => e as Map<String, dynamic>).toList()
        : [],
    difficulty: data['difficulty'] ?? 'beginner',
    durationWeeks: (data['duration_weeks'] as num?)?.toInt() ?? 4,
    enrolledCount: (data['enrolled_count'] as num?)?.toInt() ?? 0,
    isPublished: data['is_published'] == true,
    createdAt: _parseDate(data['created_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

class AcademyEnrollment {
  final String id;
  final String courseId;
  final String studentId;
  final int progressPct;
  final String? grade;
  final bool completed;
  final DateTime? completedAt;
  final DateTime enrolledAt;

  const AcademyEnrollment({
    required this.id,
    required this.courseId,
    required this.studentId,
    this.progressPct = 0,
    this.grade,
    this.completed = false,
    this.completedAt,
    required this.enrolledAt,
  });

  static AcademyEnrollment fromSupabase(Map<String, dynamic> data) => AcademyEnrollment(
    id: data['id'] ?? '',
    courseId: data['course_id'] ?? '',
    studentId: data['student_id'] ?? '',
    progressPct: (data['progress_pct'] as num?)?.toInt() ?? 0,
    grade: data['grade'],
    completed: data['completed'] == true,
    completedAt: data['completed_at'] != null ? DateTime.tryParse(data['completed_at']) : null,
    enrolledAt: _parseDate(data['enrolled_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

class AcademyAssignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final int maxPoints;
  final DateTime createdAt;

  const AcademyAssignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.dueDate,
    this.maxPoints = 100,
    required this.createdAt,
  });

  static AcademyAssignment fromSupabase(Map<String, dynamic> data) => AcademyAssignment(
    id: data['id'] ?? '',
    courseId: data['course_id'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    dueDate: data['due_date'] != null ? DateTime.tryParse(data['due_date']) : null,
    maxPoints: (data['max_points'] as num?)?.toInt() ?? 100,
    createdAt: _parseDate(data['created_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
