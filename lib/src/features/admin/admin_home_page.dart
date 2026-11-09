import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        context.go(AppRoutes.adminSubjects);
        break;
      case 2:
        context.go(AppRoutes.adminSettings);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: true,
      body: SafeArea(
        top: true,
        child: authState is AuthAuthenticated
            ? _buildDashboardContent()
            : Center(
                child: Text(
                  'Not logged in',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassNavBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.subject_outlined),
          selectedIcon: Icon(Icons.subject_rounded),
          label: 'Subjects',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
      isDark: Theme.of(context).brightness == Brightness.dark,
      accentColor: colorScheme.primary,
    );
  }

  Widget _buildDashboardContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Loading dashboard...',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Failed to load dashboard',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    snapshot.error.toString(),
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  PillButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: () => setState(() {}),
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: colorScheme.primary,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space6,
                DesignTokens.space6,
                DesignTokens.space6,
                DesignTokens.space6 + 120,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colorScheme, textTheme),
                    const SizedBox(height: DesignTokens.space6),

                    Text(
                      'Overview',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    _buildStatsGrid(stats, context),
                    const SizedBox(height: DesignTokens.space6),

                    Text(
                      'Quick Actions',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    _buildQuickActions(context),
                    const SizedBox(height: DesignTokens.space6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Sessions',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.adminRecords),
                          child: Text(
                            'View All',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    _buildRecentSessions(context),
                  ],
                ),
              ),
            ),
          );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    final authState = ref.read(authProvider);
    String greeting = 'Welcome back';
    String name = 'Admin';

    if (authState is AuthAuthenticated) {
      final student = authState.session.student;
      if (student != null && student.fullName.isNotEmpty) {
        name = student.fullName;
      }
      final hour = DateTime.now().hour;
      if (hour < 12) {
        greeting = 'Good morning';
      } else if (hour < 17) {
        greeting = 'Good afternoon';
      } else {
        greeting = 'Good evening';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Here\'s what\'s happening today',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _buildProfileMenu(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(ColorScheme colorScheme, TextTheme textTheme) {
    final bgColor = colorScheme.surfaceContainerHighest;
    final authState = ref.read(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final user = session?.student;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            if (mounted) context.push(AppRoutes.studentProfile);
            break;
          case 'change_avatar':
            _showChangeAvatarDialog();
            break;
          case 'logout':
            _showLogoutDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        if (user != null) ...[
          PopupMenuItem<String>(
            enabled: false,
            padding: const EdgeInsets.all(DesignTokens.space3),
            child: Row(
              children: [
                AvatarCircle(
                  name: user.fullName,
                  size: 40,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        session?.user.email ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: DesignTokens.space2),
              Text('My Profile', style: textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_avatar',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: DesignTokens.space2),
              Text('Change Picture', style: textTheme.labelLarge),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: colorScheme.error),
              const SizedBox(width: DesignTokens.space2),
              Text('Logout', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: AvatarCircle(
          name: user?.fullName,
          size: 36,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  void _showChangeAvatarDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => KeyboardSafeDialog(
        isDark: Theme.of(context).brightness == Brightness.dark,
        title: 'Change Profile Picture',
        content: Text(
          'This feature will be implemented soon. You can pick an image from gallery or camera.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement image picker
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Pick Image',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => KeyboardSafeDialog(
        isDark: Theme.of(context).brightness == Brightness.dark,
        title: 'Logout',
        content: Text(
          'Are you sure you want to logout?',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Logout',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      _StatItem('Subjects', stats['totalSubjects'].toString(), Icons.subject_rounded, colorScheme.primary),
      _StatItem('Students', stats['totalStudents'].toString(), Icons.people_rounded, colorScheme.secondary),
      _StatItem('Active Sessions', stats['activeSessions'].toString(), Icons.event_rounded, Color(0xFF1B8A3A)),
      _StatItem('Today\'s Sessions', stats['todaySessions'].toString(), Icons.today_rounded, Color(0xFFF5A623)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.space4,
        mainAxisSpacing: DesignTokens.space4,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildStatCard(items[index], colorScheme, index);
      },
    );
  }

  Widget _buildStatCard(_StatItem item, ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: DesignTokens.curveStandard,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: SoftCard(
        isDark: Theme.of(context).brightness == Brightness.dark,
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space2),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 20,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  style: DesignTokens.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Flexible(
              child: Text(
                item.label,
                style: DesignTokens.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = [
      _QuickAction(
        'New Session',
        Icons.add_circle_outline_rounded,
        colorScheme.primary,
        () => context.go(AppRoutes.adminSubjects),
      ),
      _QuickAction(
        'Start Scan',
        Icons.qr_code_scanner_rounded,
        Color(0xFF1B8A3A),
        () => context.push(AppRoutes.adminScan),
      ),
      _QuickAction(
        'View Records',
        Icons.assessment_outlined,
        Color(0xFFF5A623),
        () => context.go(AppRoutes.adminRecords),
      ),
      _QuickAction(
        'Manage Subjects',
        Icons.subject_outlined,
        colorScheme.secondary,
        () => context.go(AppRoutes.adminSubjects),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.space4,
        mainAxisSpacing: DesignTokens.space4,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _buildActionCard(actions[index], colorScheme, index);
      },
    );
  }

  Widget _buildActionCard(_QuickAction action, ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: DesignTokens.curveStandard,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: SoftTile(
        isDark: Theme.of(context).brightness == Brightness.dark,
        onTap: action.onTap,
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 28,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              action.label,
              style: DesignTokens.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<Session>>(
      future: _fetchRecentSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SoftCard(
            isDark: Theme.of(context).brightness == Brightness.dark,
            padding: const EdgeInsets.all(DesignTokens.space6),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Loading sessions...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return SoftCard(
            isDark: Theme.of(context).brightness == Brightness.dark,
            padding: const EdgeInsets.all(DesignTokens.space6),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'No recent sessions',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Create a session from the Subjects tab',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final sessions = snapshot.data!.take(5).toList();

        return SoftCard(
          isDark: Theme.of(context).brightness == Brightness.dark,
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(DesignTokens.space2),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              indent: DesignTokens.space4,
              endIndent: DesignTokens.space4,
              color: colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionListItem(session, colorScheme);
            },
          ),
        );
      },
    );
  }

  Widget _buildSessionListItem(Session session, ColorScheme colorScheme) {
    final statusColor = session.status == 'open' ? Color(0xFF1B8A3A) : colorScheme.onSurfaceVariant;
    final statusBg = session.status == 'open'
        ? Color(0xFF1B8A3A).withValues(alpha: 0.12)
        : colorScheme.surfaceContainerHighest;

    return InkWell(
      onTap: () => context.push('${AppRoutes.adminRecords}?sessionId=${session.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
              child: Icon(
                Icons.event_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session ${session.id}',
                    style: DesignTokens.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${session.date} • ${session.startTime} - ${session.endTime}',
                    style: DesignTokens.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space1,
              ),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              ),
              child: Text(
                session.status == 'open' ? 'Open' : 'Closed',
                style: DesignTokens.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    final subjectRepo = SubjectRepository();
    final studentRepo = StudentRepository();
    final sessionRepo = SessionRepository();
    final attendanceRepo = AttendanceRepository();

    final subjects = await subjectRepo.getAll();
    final students = await studentRepo.getAll();
    final sessions = await sessionRepo.getOpenSessions();

    final now = DateTime.now();
    final todayStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final todaySessions = await sessionRepo.getSessionsForDate(todayStr);

    int todayPresent = 0;
    int todayLate = 0;
    int todayAbsent = 0;

    for (final session in todaySessions) {
      final counts = await attendanceRepo.getCountsBySession(session.id!);
      todayPresent += counts['present'] ?? 0;
      todayLate += counts['late'] ?? 0;
      todayAbsent += counts['absent'] ?? 0;
    }

    return {
      'totalSubjects': subjects.length,
      'totalStudents': students.length,
      'activeSessions': sessions.length,
      'todaySessions': todaySessions.length,
      'todayPresent': todayPresent,
      'todayLate': todayLate,
      'todayAbsent': todayAbsent,
    };
  }

  Future<List<Session>> _fetchRecentSessions() async {
    final sessionRepo = SessionRepository();
    final sessions = await sessionRepo.getOpenSessions();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction(this.label, this.icon, this.color, this.onTap);
}