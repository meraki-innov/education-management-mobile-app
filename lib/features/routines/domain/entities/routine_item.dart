class RoutineItem {
  final String uid;
  final String title;
  final String classUid;
  final String routineType; // 'class_routine' | 'exam_routine'
  final DateTime publishDate;
  final int? sizeBytes;
  final String fileUrl;

  RoutineItem({
    required this.uid,
    required this.title,
    required this.classUid,
    required this.routineType,
    required this.publishDate,
    this.sizeBytes,
    required this.fileUrl,
  });

  String get routineTypeLabel =>
      routineType == 'exam_routine' ? 'Exam Routine' : 'Class Routine';

  String get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return '-';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
