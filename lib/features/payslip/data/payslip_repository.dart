import '../domain/entities/payslip.dart';

abstract class PayslipRepository {
  Future<List<Payslip>> getMyPayslips();
}

class LocalPayslipRepository implements PayslipRepository {
  @override
  Future<List<Payslip>> getMyPayslips() async {
    return const [
      Payslip(
        year: 2026,
        month: 10,
        workingDays: 24,
        netSalary: 47000,
        status: PayslipStatus.paid,
      ),
    ];
  }
}
