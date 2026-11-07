// A subject on the student's own "My Subjects" page (features/class/domain
// for the student view — same Academics > Class menu item as the teacher's
// ClassListScreen, just a different screen depending on role).
class StudentSubject {
  final String subjectUid;
  final String name;
  final String? code;
  final String
  subjectType; // core_compulsory, religion_moral, group_subject, optional_subject
  final String
  effectiveRole; // core_compulsory, religion_moral, group_subject, gender_based, optional, fourth_subject

  StudentSubject({
    required this.subjectUid,
    required this.name,
    this.code,
    required this.subjectType,
    required this.effectiveRole,
  });

  // Matches the tag text on the web's subject cards (Compulsory,
  // Religion & Moral, Gender Based, ...).
  String get tagLabel {
    switch (effectiveRole) {
      case 'core_compulsory':
        return 'Compulsory';
      case 'religion_moral':
        return 'Religion & Moral';
      case 'group_subject':
        return 'Group Subject';
      case 'gender_based':
        return 'Gender Based';
      case 'fourth_subject':
        return '4th Subject';
      case 'optional':
        return 'Optional';
      default:
        return effectiveRole;
    }
  }
}
