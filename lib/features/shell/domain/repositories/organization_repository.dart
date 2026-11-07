import '../entities/organization_info.dart';

abstract class OrganizationRepository {
  Future<OrganizationInfo> getOrganization();
}