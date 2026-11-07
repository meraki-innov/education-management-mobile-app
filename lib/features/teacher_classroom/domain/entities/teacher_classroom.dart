enum ClassroomRole { classTeacher, subjectTeacher }

extension ClassroomRoleX on ClassroomRole {
  String get chipLabel =>
      this == ClassroomRole.classTeacher ? "Class Teacher" : "Subject Teacher";
}

class TeacherClassroom {
  const TeacherClassroom({
    required this.className, // "Class 6"
    required this.section, // "A"
    required this.subject,
    required this.role,
  });
  final String className;
  final String section;
  final String subject;
  final ClassroomRole role;

  String get title => '$className - $section';
}
