import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../domain/entities/organization_info.dart';
import '../../domain/repositories/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl();
});

final organizationProvider = FutureProvider<OrganizationInfo>((ref) {
  return ref.watch(organizationRepositoryProvider).getOrganization();
});