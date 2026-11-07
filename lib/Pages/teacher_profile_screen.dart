import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../features/teacher_profile/domain/entities/teacher_profile.dart';
import '../features/teacher_profile/presentation/providers/teacher_profile_provider.dart';

// Teachers > Teacher Profile. Same sections as the web: header, 4 stat tiles,
// Academic & Professional, Personal, Contact, Bank & Salary, Emergency Contact.

const _gradient = LinearGradient(
  colors: [Color(0xFF4F3BD8), Color(0xFF7C6BFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

String _dash(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;
String _date(DateTime d) => DateFormat('MMM dd, yyyy').format(d);
String _money(double v) => 'BDT ${NumberFormat('#,##0.##').format(v)}';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(teacherProfileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (p) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherProfileProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(p: p),
                const SizedBox(height: 14),
                _StatGrid(p: p),
                const SizedBox(height: 14),
                _Section(
                  title: 'Academic & Professional Information',
                  icon: Icons.school_outlined,
                  rows: [
                    _Row('Employee ID', p.employeeId),
                    _Row('Designation', p.designation),
                    _Row('Qualification', p.qualification),
                    _Row('Experience', p.experienceLabel),
                    _Row('Employment Type', p.employmentType),
                    _Row('Joining Date', _date(p.joiningDate)),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Personal Information',
                  icon: Icons.badge_outlined,
                  rows: [
                    _Row('Full Name', p.fullName),
                    _Row('Gender', p.gender),
                    _Row('Date of Birth', _date(p.dateOfBirth)),
                    _Row(
                      'Blood Group',
                      _dash(p.bloodGroup),
                      badge: p.bloodGroup != null,
                    ),
                    _Row('National ID', _dash(p.nationalId)),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Contact Details',
                  icon: Icons.contact_mail_outlined,
                  rows: [
                    _Row('Email Address', p.email),
                    _Row('Phone Number', p.phone),
                    _Row('Alternate Phone', _dash(p.alternatePhone)),
                    _Row('Current Address', _dash(p.currentAddress)),
                    _Row('Permanent Address', _dash(p.permanentAddress)),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Bank & Salary Information',
                  icon: Icons.account_balance_outlined,
                  rows: [
                    _Row('Salary', p.salary == null ? '—' : _money(p.salary!)),
                    _Row('Bank Name', _dash(p.bankName)),
                    _Row('Bank Branch', _dash(p.bankBranch)),
                    _Row('Account Number', _dash(p.accountNumber)),
                    _Row('IFSC Code', _dash(p.ifscCode)),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Emergency Contact',
                  icon: Icons.contact_phone_outlined,
                  rows: [
                    _Row('Contact Name', _dash(p.emergencyContactName)),
                    _Row('Relation', _dash(p.emergencyRelation)),
                    _Row('Contact Phone', _dash(p.emergencyPhone)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: avatar, name, designation, id/joined, chips, actions
// ---------------------------------------------------------------------------
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.p});
  final TeacherProfile p;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _Chip(
        p.isActive ? 'Active' : 'Inactive',
        p.isActive ? context.successColor : context.mutedText,
      ),
      _Chip(p.qualification, null),
      _Chip(p.employmentType, context.brandColor),
      _Chip('${p.experienceLabel} Experience', context.brandColor),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary700,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      p.initials,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (p.isActive)
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: context.successColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.designation,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _IconText(Icons.badge_outlined, p.employeeId),
                        _IconText(
                          Icons.event_outlined,
                          'Joined: ${_date(p.joiningDate)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _notBuilt(context, 'Edit Profile'),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.isDark
                        ? AppColors.darkButton
                        : AppColors.primary700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notBuilt(context, 'ID Card'),
                  icon: const Icon(Icons.download_outlined, size: 17),
                  label: const Text('ID Card'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _notBuilt(BuildContext context, String what) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$what is not built yet')));
}

class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.mutedText),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color? color; // null = neutral

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 stat tiles (2 x 2 on phones)
// ---------------------------------------------------------------------------
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.p});
  final TeacherProfile p;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        label: 'EXPERIENCE',
        value: p.experienceLabel,
        subIcon: Icons.school_outlined,
        sub: p.qualification,
        icon: Icons.work_outline_rounded,
        filled: true,
      ),
      _StatTile(
        label: 'EMPLOYMENT TYPE',
        value: p.employmentType,
        subIcon: Icons.check_circle_outline,
        sub: 'Status: ${p.status}',
        icon: Icons.account_tree_outlined,
        filled: false,
      ),
      _StatTile(
        label: 'SALARY',
        value: p.salary == null ? '—' : _money(p.salary!),
        subIcon: Icons.account_balance_outlined,
        sub: p.hasBank ? p.bankName! : 'Bank not added',
        icon: Icons.payments_outlined,
        filled: true,
      ),
      _StatTile(
        label: 'CLASS TEACHER',
        value: p.isClassTeacher ? 'Yes' : 'No',
        subIcon: Icons.meeting_room_outlined,
        sub: p.isClassTeacher ? p.assignedClass! : 'No assigned class',
        icon: Icons.calendar_month_outlined,
        filled: false,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.subIcon,
    required this.icon,
    required this.filled,
  });
  final String label;
  final String value;
  final String sub;
  final IconData subIcon;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : null;
    final subColor = filled
        ? Colors.white.withValues(alpha: 0.9)
        : context.mutedText;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: filled ? _gradient : null,
        color: filled ? null : context.surfaceColor,
        border: filled ? null : Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: fg,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.2)
                      : context.brandColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: filled ? Colors.white : context.brandColor,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          Row(
            children: [
              Icon(subIcon, size: 13, color: subColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info sections: label on the left, value on the right
// ---------------------------------------------------------------------------
class _Row {
  const _Row(this.label, this.value, {this.badge = false});
  final String label;
  final String value;
  final bool badge; // shown as a red pill (blood group)
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.rows});
  final String title;
  final IconData icon;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.iconBoxColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++) ...[
            _InfoRow(row: rows[i]),
            if (i != rows.length - 1)
              Divider(height: 1, color: context.borderColor),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final valueStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              row.label,
              style: TextStyle(fontSize: 13.5, color: context.mutedText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: row.badge
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.dangerColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        row.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.dangerColor,
                        ),
                      ),
                    )
                  : Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
