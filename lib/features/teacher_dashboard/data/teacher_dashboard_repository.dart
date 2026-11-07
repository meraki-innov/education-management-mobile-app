import '../domain/entities/teacher_dashboard.dart';

abstract class TeacherDashboardRespository {
  Future<TeacherDashboard> getDashboard();
}

class LocalTeacherDashboardRepository implements TeacherDashboardRespository {
  @override
  Future<TeacherDashboard> getDashboard() async {
    return TeacherDashboard(
      subjects: const [
        'Bangla',
        'English',
        'Mathematics',
        'General Science',
        'ICT',
        'Religion',
        'Agriculture',
      ],
      assessmentCount: 0,
      students: const [
        TeacherStudent(
          rollNo: '01',
          name: 'rakib dk',
          email: 'dktest@gmail.com',
          className: 'Class 6',
          section: 'Section A',
        ),
        TeacherStudent(
          rollNo: '1',
          name: 'Rahim Uddi',
          email: 'djkarim@gmail.com',
          className: 'Class 7',
          section: 'Section A',
        ),
        TeacherStudent(
          rollNo: 'ROLL01',
          name: 'Nahid Akhter',
          email: 'nahid@gmail.com',
          className: 'Class 7',
          section: 'Section A',
        ),
        TeacherStudent(
          rollNo: '11111',
          name: 'test name',
          email: 'studenttest@gmail.com',
          className: 'Class 6',
          section: 'Section A',
        ),
        TeacherStudent(
          rollNo: 'C8-05',
          name: 'Fardin Islam',
          email: 'c8.student05@shaplamodel.edu.bd',
          className: 'Class 8',
          section: 'Section A',
        ),
        TeacherStudent(
          rollNo: 'C8-06',
          name: 'Mehjabin Islam',
          email: 'c8.student06@shaplamodel.edu.bd',
          className: 'Class 8',
          section: 'Section A',
        ),
      ],
      assignments: const [],
      today: const TodayAttendance(present: 0, absent: 0, late: 0),
      weekly: const [
        WeeklyAttendancePoint('Mon', 85),
        WeeklyAttendancePoint('Tue', 92),
        WeeklyAttendancePoint('Wed', 78),
        WeeklyAttendancePoint('Thu', 88),
        WeeklyAttendancePoint('Fri', 94),
        WeeklyAttendancePoint('Sat', 65),
        WeeklyAttendancePoint('Sun', 70),
      ],
      events: [
        CalendarEvent(
          title: 'Holiday',
          description: 'This is national Holiday',
          date: DateTime(2026, 11, 5),
          isHoliday: true,
        ),
      ],
      notices: [
        TeacherNotice(
          title: 'test notice',
          body: 'this is test notice',
          date: DateTime(2026, 10, 13),
          priority: 'Normal',
        ),
      ],
    );
  }
}
