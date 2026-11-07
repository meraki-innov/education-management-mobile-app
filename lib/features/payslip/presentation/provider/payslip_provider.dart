import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/payslip_repository.dart';
import '../../domain/entities/payslip.dart';

final payslipRepositoryProvider = Provider<PayslipRepository>(
  (ref) => LocalPayslipRepository(),
);

final payslipsProvider = FutureProvider<List<Payslip>>((ref) {
  return ref.watch(payslipRepositoryProvider).getMyPayslips();
});
