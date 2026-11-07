// lib/features/teacher_profile/data/teacher_profile_repository.dart
//
// LOCAL for now (no API). When the endpoint is ready, add an API
// implementation that builds the same TeacherProfile and swap it in
// teacher_profile_provider.dart. The screen does not change.

import '../domain/entities/teacher_profile.dart';

abstract class TeacherProfileRepository {
  Future<TeacherProfile> getMyProfile();
}

class LocalTeacherProfileRepository implements TeacherProfileRepository {
  @override
  Future<TeacherProfile> getMyProfile() async {
    return TeacherProfile(
      employeeId: 'SMS-T-004',
      fullName: 'Nusrat Jahan',
      designation: 'Assistant Teacher (General Science)',
      qualification: 'Master’s degree in relevant subject',
      experienceYears: 11,
      employmentType: 'Permanent',
      status: 'active',
      joiningDate: DateTime(2020, 1, 1),
      gender: 'Female',
      dateOfBirth: DateTime(1985, 1, 15),
      bloodGroup: 'O+',
      email: 'teacher004@shaplamodel.edu.bd',
      phone: '01010000004',
      currentAddress: 'Mirpur, Dhaka',
      permanentAddress: 'Dhaka, Bangladesh',
      salary: 47000,
      // Bank, national ID, alternate phone, emergency contact and class
      // assignment are empty on the web, so they are null here too.
    );
  }
}
