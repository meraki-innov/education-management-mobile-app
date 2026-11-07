class UserProfile {
  final String firstName;
  final String lastName;
  final String roleName;
  final String imageUrl;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.roleName,
    required this.imageUrl,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}
