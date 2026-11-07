import '../entities/student_subject.dart';

abstract class StudentSubjectsRepository {
  Future<List<StudentSubject>> getMySubjects();

  // The class_uid of the student's own active enrollment — used to lock the
  // Routines screen's class filter to their own class.
  Future<String> getMyClassUid();
}
