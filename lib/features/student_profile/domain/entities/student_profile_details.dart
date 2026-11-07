// Full profile shown on Students > Student Profile.
class StudentProfileDetails {
  final String firstName;
  final String lastName;
  final String email;
  final String rollNumber;
  final String? gender;
  final String? dateOfBirth; // YYYY-MM-DD from the backend
  final String? bloodGroup;
  final String? activityStatus;
  final String? className;
  final String? sectionName;
  final String? academicYearName;
  final String? roleName;
  final String? currentAddress;
  final String? permanentAddress;
  final String? imageUrl;

  StudentProfileDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.rollNumber,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.activityStatus,
    this.className,
    this.sectionName,
    this.academicYearName,
    this.roleName,
    this.currentAddress,
    this.permanentAddress,
    this.imageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isEmpty ? '' : firstName[0];
    final l = lastName.isEmpty ? '' : lastName[0];
    return (f + l).toUpperCase();
  }
}
