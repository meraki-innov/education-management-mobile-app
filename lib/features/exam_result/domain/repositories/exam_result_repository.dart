import '../entities/exam_result_row.dart';
import '../entities/subject_performance_slice.dart';

abstract class ExamResultRepository {
  // No parameters on purpose: it picks the student's current class, their
  // current academic year, and the first matching assessment category,
  // exactly like the web page does on first load. Picking a different
  // academic year or category is a later feature, not this one.
  Future<List<ExamResultRow>> getExamResults();

  // Same underlying marks data as getExamResults(), just grouped by
  // subject instead of listed row by row — for the donut chart.
  Future<List<SubjectPerformanceSlice>> getSubjectPerformance();
}
