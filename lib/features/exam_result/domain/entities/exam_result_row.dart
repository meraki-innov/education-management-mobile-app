// One component inside a subject's total — e.g. "Class Test", "CQ (Final
// Exam)", "Mid Exam". This is what powers the "View" breakdown dialog,
// matching the web's per-subject marks-detail modal.
class AssessmentComponentDetail {
  final String title; // e.g. "Class Test", "CQ (Final Exam)", "Mid Exam"
  final double marksObtained;
  final double fullMark;
  final double weightedMarks;
  final double? weightage; // this component's weight, as a percent (0-100)
  final bool isAbsent;

  AssessmentComponentDetail({
    required this.title,
    required this.marksObtained,
    required this.fullMark,
    required this.weightedMarks,
    this.weightage,
    this.isAbsent = false,
  });
}

class ExamResultRow {
  final String subjectName;
  final double marksObtained;
  final double fullMark;
  final double weightedMarks;
  final String grade; // A+, A, A-, B, C, D, F
  final String performance; // Excellent, Very Good, ... Fail
  final String statusLabel; // "Passed" or "Failed"
  final bool isPassed;

  // The individual assessments (Class Test, Final Exam, CQ, MCQ, Mid Exam,
  // Quiz, ...) that were summed to make this subject's total. Empty when
  // the data source didn't provide a breakdown.
  final List<AssessmentComponentDetail> assessments;

  ExamResultRow({
    required this.subjectName,
    required this.marksObtained,
    required this.fullMark,
    required this.weightedMarks,
    required this.grade,
    required this.performance,
    required this.statusLabel,
    required this.isPassed,
    this.assessments = const [],
  });
}
