enum PayslipStatus { paid, pending }

extension PayslipStatusX on PayslipStatus {
  String get label => this == PayslipStatus.paid ? "Paid" : "Pending";
}

class Payslip {
  const Payslip({
    required this.year,
    required this.month,
    required this.workingDays,
    required this.netSalary,
    required this.status,
  });
  final int year;
  final int month;
  final int workingDays;
  final double netSalary;
  final PayslipStatus status;

  int get periodKey => year * 12 + month;
}

class PayslipSummary {
  const PayslipSummary(this.slips);
  final List<Payslip> slips;

  int get totalSlips => slips.length;

  Payslip? get latest {
    if (slips.isEmpty) return null;
    return slips.reduce((a, b) => a.periodKey >= b.periodKey ? a : b);
  }
}
