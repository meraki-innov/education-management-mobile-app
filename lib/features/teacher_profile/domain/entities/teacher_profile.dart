// lib/features/teacher_profile/domain/entities/teacher_profile.dart
//
// What the Teacher Profile screen works with. Optional fields (null) show as
// "—" on screen; the header chips, experience text, initials and the
// "Bank not added" hint are all DERIVED from these fields.

class TeacherProfile {
  const TeacherProfile({
    required this.employeeId,
    required this.fullName,
    required this.designation,
    required this.qualification,
    required this.experienceYears,
    required this.employmentType,
    required this.status,
    required this.joiningDate,
    required this.gender,
    required this.dateOfBirth,
    required this.email,
    required this.phone,
    this.salary,
    this.assignedClass,
    this.bloodGroup,
    this.nationalId,
    this.alternatePhone,
    this.currentAddress,
    this.permanentAddress,
    this.bankName,
    this.bankBranch,
    this.accountNumber,
    this.ifscCode,
    this.emergencyContactName,
    this.emergencyRelation,
    this.emergencyPhone,
  });

  final String employeeId;
  final String fullName;
  final String designation;
  final String qualification;
  final int experienceYears;
  final String employmentType; // Permanent / Contractual ...
  final String status; // active / inactive
  final DateTime joiningDate;
  final String gender;
  final DateTime dateOfBirth;
  final String email;
  final String phone;

  final double? salary;
  final String? assignedClass; // null = not a class teacher
  final String? bloodGroup;
  final String? nationalId;
  final String? alternatePhone;
  final String? currentAddress;
  final String? permanentAddress;
  final String? bankName;
  final String? bankBranch;
  final String? accountNumber;
  final String? ifscCode;
  final String? emergencyContactName;
  final String? emergencyRelation;
  final String? emergencyPhone;

  // Derived
  bool get isActive => status.toLowerCase() == 'active';
  bool get isClassTeacher => assignedClass != null && assignedClass!.trim().isNotEmpty;
  bool get hasBank => bankName != null && bankName!.trim().isNotEmpty;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String get experienceLabel => '$experienceYears ${experienceYears == 1 ? 'Year' : 'Years'}';
}