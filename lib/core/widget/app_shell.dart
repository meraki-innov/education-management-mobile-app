import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/presentation/providers/login_provider.dart';
import '../../features/shell/presentation/providers/shell_provider.dart';
import '../../Pages/login_page.dart';
import '../../Pages/class_list_screen.dart';
import '../../Pages/my_subjects_screen.dart';
import '../../Pages/routine_screen.dart';
import '../../Pages/student_profile_screen.dart';
import '../../Pages/exam_result_screen.dart';
import '../../Pages/fee_invoices_screen.dart';
import '../../Pages/teacher_profile_screen.dart';

const double _topRowHeight = 60;
const double _searchRowHeight = 56;

// ---------------------------------------------------------------------------
// TOP BAR: logo + name + menu button on the left; theme toggle, bell and
// profile on the right. The search field sits in a second row because a phone
// is too narrow to fit it beside everything else.
// ---------------------------------------------------------------------------
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.notificationCount = 0});

  // TODO: feed this from the notifications API. The web shows a red badge.
  final int notificationCount;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_topRowHeight + _searchRowHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    // The web hides the product name on small screens and keeps the logo only.
    final showName = MediaQuery.of(context).size.width >= 400;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _topRowHeight,
      titleSpacing: 12,
      shape: Border(bottom: BorderSide(color: context.borderColor)),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.brandColor,
              borderRadius: BorderRadius.circular(8),
            ),
            // TODO: swap for the real BornoPoth logo asset.
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          if (showName) ...[
            const SizedBox(width: 8),
            const Text(
              'BORNOPOTH',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
          const SizedBox(width: 4),
          // Builder gives us a context that is inside the Scaffold, which is
          // what openDrawer() needs.
          Builder(
            builder: (scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            ),
          ),
        ],
      ),
      actions: [
        // Sun in dark mode (tap for light), moon in light mode (tap for dark).
        GestureDetector(
          onTap: () {
            ref.read(themeModeProvider.notifier).state = isDark
                ? ThemeMode.light
                : ThemeMode.dark;
          },
          child: _IconBox(
            child: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? Colors.amber : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const _IconBox(child: Icon(Icons.notifications_none, size: 22)),
            if (notificationCount > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        const _ProfileMenu(),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_searchRowHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SizedBox(
            height: 44,
            child: TextField(
              // TODO: make this search the sidebar menu items.
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Search menus and pages...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: context.iconBoxColor,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The small rounded square behind each icon in the top bar.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.child, this.round = false});
  final Widget child;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.iconBoxColor,
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// Round person icon. Tapping shows the account card + menu, matching the
// web's profile dropdown. "My Profile" (students) and "Logout" work; the
// rest are visible placeholders until their screens exist.
class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final roleLabel = (user == null || user.roleName.isEmpty)
        ? ''
        : user.roleName[0].toUpperCase() + user.roleName.substring(1);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      padding: EdgeInsets.zero,
      itemBuilder: (menuContext) => [
        // Account header card: avatar, name, email, role chip.
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Not signed in',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (roleLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.selectedColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.brandColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        _profileItem('My Profile', Icons.person_outline),
        _profileItem('Settings', Icons.settings_outlined),
        _profileItem('Activity', Icons.show_chart_rounded, badgeCount: 3),
        _profileItem('Billing', Icons.credit_card_outlined),
        _profileItem('Privacy & Security', Icons.shield_outlined),
        const PopupMenuDivider(),
        _profileItem('Help Center', Icons.help_outline),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: Color(0xFFE65956)),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFE65956),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          // Clear the stored login info (same keys used elsewhere in the
          // app — access_token, branch_uid, user_uid, etc.), then clear the
          // ENTIRE navigation stack and push a fresh LoginScreen. This
          // works regardless of how the dashboard was reached (push vs
          // pushReplacement, named routes, nested navigators, ...) — unlike
          // popUntil, which only works if LoginScreen happens to already be
          // sitting at the bottom of the current stack.
          const storage = FlutterSecureStorage();
          await storage.deleteAll();
          ref.invalidate(currentUserProvider);
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        } else if (value == 'My Profile' && user?.roleName == 'student') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
          );
        } else if (value == 'My Profile' && user?.roleName == 'teacher') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TeacherProfileScreen()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$value is not built yet')));
        }
      },
      child: const _IconBox(round: true, child: Icon(Icons.person, size: 22)),
    );
  }

  // Inactive-for-now items (My Profile, Settings, Activity, Billing,
  // Privacy & Security, Help Center) all route through here so they show a
  // "not built yet" message instead of doing nothing silently.
  PopupMenuItem<String> _profileItem(
    String label,
    IconData icon, {
    int? badgeCount,
  }) {
    return PopupMenuItem<String>(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF5F4AFF),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SIDEBAR: on the web it is always visible; on a phone it slides in as a
// drawer from the menu button.
// ---------------------------------------------------------------------------
class _SubItem {
  const _SubItem(this.label, [this.screenBuilder]);
  final String label;
  // Takes WidgetRef so a destination can depend on the logged-in user's role
  // (e.g. Class). null = screen not built yet.
  final Widget Function(WidgetRef ref)? screenBuilder;
}

class _MenuItem {
  const _MenuItem(
    this.label,
    this.icon,
    this.color, {
    this.children = const [],
  });
  final String label;
  final IconData icon;
  final Color color;
  final List<_SubItem> children;
}

// Student sidebar, matching the web: Dashboard, Students, Academics.
final _menu = <_MenuItem>[
  const _MenuItem('Dashboard', Icons.home_rounded, Color(0xFF29B6D9)),
  _MenuItem(
    'Students',
    Icons.school_rounded,
    const Color(0xFFF5A42B),
    children: [
      _SubItem('Student Profile', (ref) => const StudentProfileScreen()),
      _SubItem('Exam Result', (ref) => const ExamResultScreen()),
      const _SubItem('Leave Application'),
    ],
  ),
  _MenuItem(
    'Academics',
    Icons.menu_book_rounded,
    const Color(0xFF26A572),
    children: [
      // Same "Class" entry for everyone; what it opens depends on role.
      _SubItem('Class', (ref) {
        final role = ref.read(currentUserProvider).valueOrNull?.roleName;
        final isStaff =
            role == 'teacher' ||
            role == 'school_admin' ||
            role == 'branch_admin' ||
            role == 'employee';
        return isStaff ? const ClassListScreen() : const MySubjectsScreen();
      }),
      _SubItem('Routines', (ref) => const RoutinesScreen()),
    ],
  ),
  _MenuItem(
    'Fees',
    Icons.payments_rounded,
    const Color(0xFFE5484D),
    children: [_SubItem('My Fee Invoices', (ref) => const FeeInvoicesScreen())],
  ),
];

// Teacher sidebar, matching the web: Dashboard, Teachers, Academics, HRM.
// Sub-items without a screen show "not built yet" until we build them.
final _teacherMenu = <_MenuItem>[
  const _MenuItem('Dashboard', Icons.home_rounded, Color(0xFF29B6D9)),
  _MenuItem(
    'Teachers',
    Icons.co_present_rounded,
    const Color(0xFF26A572),
    children: [
      _SubItem('Teacher Profile', (ref) => const TeacherProfileScreen()),
    ],
  ),
  _MenuItem(
    'Academics',
    Icons.menu_book_rounded,
    const Color(0xFFF5A42B),
    children: [
      _SubItem('Class', (ref) => const ClassListScreen()),
      _SubItem('Routines', (ref) => const RoutinesScreen()),
    ],
  ),
  _MenuItem(
    'HRM',
    Icons.badge_rounded,
    const Color(0xFFE5484D),
    children: [const _SubItem('Leave Application')],
  ),
];

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, this.selected = 'Dashboard'});

  // Label of the item to highlight.
  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(organizationProvider).valueOrNull;
    final role = ref.watch(currentUserProvider).valueOrNull?.roleName;
    final menu = role == 'teacher' ? _teacherMenu : _menu;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // School and branch card. Hidden if names are empty or still loading.
            if (org != null && org.schoolName.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.schoolName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      org.branchName,
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                    ),
                  ],
                ),
              ),
            for (final item in menu) _buildItem(context, ref, item),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, _MenuItem item) {
    final isSelected = item.label == selected;
    final icon = Icon(item.icon, color: item.color, size: 22);
    final title = Text(
      item.label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );

    // Plain item with no sub-menu (Dashboard).
    if (item.children.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.selectedColor : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: icon,
          title: title,
          onTap: () => Navigator.pop(context), // already on the dashboard
        ),
      );
    }

    // Item that expands to show its sub-items.
    return Theme(
      // Hides the divider lines ExpansionTile draws by default.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: icon,
        title: title,
        children: [
          for (final sub in item.children)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 56, right: 16),
              dense: true,
              title: Text(
                sub.label,
                style: TextStyle(
                  fontSize: 14,
                  color: sub.screenBuilder == null ? context.mutedText : null,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // close the drawer first
                if (sub.screenBuilder != null) {
                  final screen = sub.screenBuilder!(ref);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => screen),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${sub.label} is not built yet')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
