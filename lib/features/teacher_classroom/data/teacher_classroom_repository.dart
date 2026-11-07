// lib/features/teacher_classrooms/data/teacher_classroom_repository.dart
//
// LOCAL for now (no API). When the endpoint is ready, add an API
// implementation that builds the same TeacherClassroom list and swap it in
// teacher_classroom_provider.dart. The screen does not change.

import '../domain/entities/teacher_classroom.dart';

abstract class TeacherClassroomRepository {
  Future<List<TeacherClassroom>> getMyClassrooms();
}

class LocalTeacherClassroomRepository implements TeacherClassroomRepository {
  @override
  Future<List<TeacherClassroom>> getMyClassrooms() async {
    const r = ClassroomRole.subjectTeacher;
    return const [
      TeacherClassroom(
        className: 'Class 6',
        section: 'A',
        subject: 'Science',
        role: r,
      ),
      TeacherClassroom(
        className: 'Class 7',
        section: 'A',
        subject: 'Science',
        role: r,
      ),
      TeacherClassroom(
        className: 'Class 8',
        section: 'A',
        subject: 'Science',
        role: r,
      ),
      TeacherClassroom(
        className: 'Class 9',
        section: 'A',
        subject: 'General Science',
        role: r,
      ),
      TeacherClassroom(
        className: 'Class 9',
        section: 'A',
        subject: 'General Science',
        role: r,
      ),
      TeacherClassroom(
        className: 'Class 10',
        section: 'A',
        subject: 'General Science',
        role: r,
      ),
      TeacherClassroom(
        className: 'Class 10',
        section: 'A',
        subject: 'General Science',
        role: r,
      ),
    ];
  }
}
