import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../features/student_profile/presentation/providers/student_profile_provider.dart';
import '../features/student_profile/domain/entities/student_profile_details.dart';

const _purpleGradient = LinearGradient(
  colors: [Color(0xFF6D5BFF), Color(0xFF4A3FE0)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

String _dash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

String _formatDob(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('dd MMM yyyy').format(d);
}

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Profile',
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
                    onPressed: () => ref.invalidate(studentProfileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (p) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentProfileProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(p: p),
                const SizedBox(height: 14),
                _StatGrid(p: p),
                const SizedBox(height: 14),
                _Section(
                  title: 'Academic Information',
                  icon: Icons.school_outlined,
                  rows: [
                    _Row('Class', _dash(p.className)),
                    _Row('Section', _dash(p.sectionName)),
                    _Row('Roll Number', _dash(p.rollNumber)),
                    _Row('Academic Year', _dash(p.academicYearName)),
                    _Row('Status', _dash(p.activityStatus), badge: true),
                    _Row('Role', _dash(p.roleName)),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Personal Information',
                  icon: Icons.badge_outlined,
                  rows: [
                    _Row('Full Name', _dash(p.fullName)),
                    _Row('Gender', _dash(p.gender)),
                    _Row('Date of Birth', _formatDob(p.dateOfBirth)),
                    _Row('Blood Group', _dash(p.bloodGroup)),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Contact Details',
                  icon: Icons.contact_mail_outlined,
                  rows: [
                    _Row('Email Address', _dash(p.email)),
                    _Row('Current Address', _dash(p.currentAddress)),
                    _Row('Permanent Address', _dash(p.permanentAddress)),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.p});
  final StudentProfileDetails p;

  @override
  Widget build(BuildContext context) {
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    final initialsBox = Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF3F3CA8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        p.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.network(
                        p.imageUrl!,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => initialsBox,
                      )
                    : initialsBox,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class ${_dash(p.className).replaceFirst('Class ', '')} — Section ${_dash(p.sectionName)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll: ${_dash(p.rollNumber)}  ·  ${_dash(p.academicYearName)}',
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dash(p.email),
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(_dash(p.activityStatus), const Color(0xFF16A34A)),
              _Chip('Section: ${_dash(p.sectionName)}', context.mutedText),
              _Chip('Student', const Color(0xFF4F46E5)),
              if (p.bloodGroup != null && p.bloodGroup!.isNotEmpty)
                _Chip('Blood Group: ${p.bloodGroup}', const Color(0xFF0E7490)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile is not built yet')),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F3CA8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.p});
  final StudentProfileDetails p;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatTile(
          label: 'ROLL NUMBER',
          value: _dash(p.rollNumber),
          sub: 'Class: ${_dash(p.className)}',
          highlighted: true,
        ),
        _StatTile(
          label: 'SECTION',
          value: _dash(p.sectionName),
          sub: _dash(p.academicYearName),
        ),
        _StatTile(
          label: 'STATUS',
          value: _dash(p.activityStatus),
          sub: _dash(p.gender),
          highlighted: true,
        ),
        _StatTile(
          label: 'BLOOD GROUP',
          value: _dash(p.bloodGroup),
          sub: 'DOB: ${_formatDob(p.dateOfBirth)}',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    this.highlighted = false,
  });
  final String label;
  final String value;
  final String sub;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : null;
    final subColor = highlighted ? Colors.white70 : context.mutedText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: highlighted ? _purpleGradient : null,
        color: highlighted ? null : context.surfaceColor,
        border: highlighted ? null : Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: fg,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: subColor),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value, {this.badge = false});
  final String label;
  final String value;
  final bool badge;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.rows});
  final String title;
  final IconData icon;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.iconBoxColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: context.brandColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      rows[i].label,
                      style: TextStyle(fontSize: 13, color: context.mutedText),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: rows[i].badge
                          ? _Chip(rows[i].value, const Color(0xFF16A34A))
                          : Text(
                              rows[i].value,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              Divider(height: 1, color: context.borderColor),
          ],
        ],
      ),
    );
  }
}
