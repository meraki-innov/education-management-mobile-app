import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exam_result_repository_impl.dart';
import '../../domain/entities/exam_result_row.dart';
import '../../domain/entities/subject_performance_slice.dart';
import '../../domain/repositories/exam_result_repository.dart';

final examResultRepositoryProvider = Provider<ExamResultRepository>((ref) {
  return ExamResultRepositoryImpl();
});

final examResultProvider = FutureProvider<List<ExamResultRow>>((ref) {
  return ref.watch(examResultRepositoryProvider).getExamResults();
});

final subjectPerformanceProvider =
    FutureProvider<List<SubjectPerformanceSlice>>((ref) {
      return ref.watch(examResultRepositoryProvider).getSubjectPerformance();
    });
