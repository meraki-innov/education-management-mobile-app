// lib/features/teacher_dashboard/domain/entities/teacher_dashboard.dart
//
// What the teacher dashboard UI works with. Every number on the screen is
// either stored here or DERIVED from these lists (student count, class count,
// attendance %), so when the real API arrives only the data layer changes.

class TeacherStudent {
  const TeacherStudent({
    required this.rollNo,
    required this.name,
    required this.email,
    required this.className,
    required this.section,
    this.isActive = true,
  });
  final String rollNo;
  final String name;
  final String email;
  final String className; // "Class 6"
  final String section; // "Section A"
  final bool isActive;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class ClassAssignment {
  const ClassAssignment({
    required this.className,
    required this.section,
    required this.subject,
  });
  final String className;
  final String section;
  final String subject;
}

class TodayAttendance {
  const TodayAttendance({
    required this.present,
    required this.absent,
    required this.late,
  });
  final int present;
  final int absent;
  final int late;

  int get total => present + absent;
  double get presentPercent => total == 0 ? 0 : present / total * 100;
}

class WeeklyAttendancePoint {
  const WeeklyAttendancePoint(this.day, this.percent);
  final String day; // Mon, Tue ...
  final double percent; // 0..100
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.description,
    required this.date,
    this.isHoliday = false,
  });
  final String title;
  final String description;
  final DateTime date;
  final bool isHoliday;
}

class TeacherNotice {
  const TeacherNotice({
    required this.title,
    required this.body,
    required this.date,
    required this.priority,
  });
  final String title;
  final String body;
  final DateTime date;
  final String priority; // Normal / Urgent ...
}

class TeacherDashboard {
  const TeacherDashboard({
    required this.subjects,
    required this.assessmentCount,
    required this.students,
    required this.assignments,
    required this.today,
    required this.weekly,
    required this.events,
    required this.notices,
  });

  final List<String> subjects;
  final int assessmentCount;
  final List<TeacherStudent> students;
  final List<ClassAssignment> assignments;
  final TodayAttendance today;
  final List<WeeklyAttendancePoint> weekly;
  final List<CalendarEvent> events;
  final List<TeacherNotice> notices;

  // Derived — never typed in by hand.
  int get studentCount => students.length;
  int get classCount => students.map((s) => s.className).toSet().length;
  int get sectionCount =>
      students.map((s) => '${s.className}|${s.section}').toSet().length;
  int get subjectCount => subjects.length;
}
