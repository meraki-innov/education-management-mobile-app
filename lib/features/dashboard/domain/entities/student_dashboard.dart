class StudentDashboard {
  final int totalAttendance;
  final int presentCount;
  final int absentCount;

  final int totalTasks;
  final int pendingTasks;

  final int totalAssessments;
  final int marksEntered;
  final double averagePercentage;

  final int unpaidInvoices;
  final int paidInvoices;
  final double totalDueAmount;

  StudentDashboard({
    required this.totalAttendance,
    required this.presentCount,
    required this.absentCount,
    required this.totalTasks,
    required this.pendingTasks,
    required this.totalAssessments,
    required this.marksEntered,
    required this.averagePercentage,
    required this.unpaidInvoices,
    required this.paidInvoices,
    required this.totalDueAmount,
  });
}
