import '../entities/student_profile_details.dart';

abstract class StudentProfileRepository {
  Future<StudentProfileDetails> getMyProfile();
}
