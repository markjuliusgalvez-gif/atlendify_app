import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_header.dart';
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

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
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
  ];

  Future<void> _handleStartScan(BuildContext context) async {
    final sessionRepo = SessionRepository();
    final openSessions = await sessionRepo.getOpenSessions();

    if (!mounted) return;

    if (openSessions.isEmpty) {
      // No active sessions - show subject picker bottom sheet or navigate to Subjects
      _showSubjectPickerForScan(context);
    } else if (openSessions.length == 1) {
      // Single active session - navigate directly to that subject's dashboard scanner
      final session = openSessions.first;
      context.push(AppRoutes.adminSubjectDashboard.replaceAll(':subjectId', session.subjectId.toString()));
    } else {
      // Multiple active sessions - show session picker
      _showSessionPickerForScan(context, openSessions);
    }
  }

  void _showSubjectPickerForScan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubjectPickerBottomSheet(
        onSubjectSelected: (subjectId) {
          Navigator.pop(context);
          context.push(AppRoutes.adminSubjectDashboard.replaceAll(':subjectId', subjectId.toString()));
        },
      ),
    );
  }

  void _showSessionPickerForScan(BuildContext context, List<Session> sessions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionPickerBottomSheet(
        sessions: sessions,
        onSessionSelected: (session) {
          Navigator.pop(context);
          context.push(AppRoutes.adminSubjectDashboard.replaceAll(':subjectId', session.subjectId.toString()));
        },
      ),
    );
  }

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
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
        accentColor: colorScheme.primary,
      ),
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

        // Compute greeting and name
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

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: colorScheme.primary,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                DesignTokens.space6,
                DesignTokens.space6,
                DesignTokens.space6,
                // Nav bar height + safe-area bottom + 16
                DesignTokens.bottomBarHeight + MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeader(
                      title: '$greeting, $name',
                      subtitle: 'Here\'s what\'s happening today',
                      showProfileMenu: true,
                    ),
                    const SizedBox(height: DesignTokens.space6),

                    // 24px above, 12px below section title
                    const SizedBox(height: 24),
                    Text(
                      'Overview',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(stats, context),
                    const SizedBox(height: DesignTokens.space6),

                    // 24px above, 12px below section title
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: DesignTokens.space6),

                    // 24px above, 12px below section title
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Sessions',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
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
                    const SizedBox(height: 12),
                    _buildRecentSessions(context),
                  ],
                ),
              ),
            ),
          );
      },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 12.0; // 12 px gaps as specified

        // Use two Rows of Expanded cards wrapped in IntrinsicHeight, 12 px gaps
        return IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(items[0], colorScheme, 0)),
                  SizedBox(width: spacing),
                  Expanded(child: _buildStatCard(items[1], colorScheme, 1)),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(child: _buildStatCard(items[2], colorScheme, 2)),
                  SizedBox(width: spacing),
                  Expanded(child: _buildStatCard(items[3], colorScheme, 3)),
                ],
              ),
            ],
          ),
        );
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
        () => _handleStartScan(context),
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

    // Same Row + Expanded + IntrinsicHeight structure, 16 px padding, minHeight ~104
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildActionCard(actions[0], colorScheme, 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(actions[1], colorScheme, 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard(actions[2], colorScheme, 2)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(actions[3], colorScheme, 3)),
            ],
          ),
        ],
      ),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 104,
        ),
        child: SoftTile(
          isDark: Theme.of(context).brightness == Brightness.dark,
          onTap: action.onTap,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 8),
              Text(
                action.label,
                style: DesignTokens.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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

/// Bottom sheet for selecting a subject when no active sessions exist
class _SubjectPickerBottomSheet extends ConsumerWidget {
  final void Function(int subjectId) onSubjectSelected;

  const _SubjectPickerBottomSheet({required this.onSubjectSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<Subject>>(
      future: SubjectRepository().getAll(),
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet)),
          ),
          padding: EdgeInsets.only(
            top: DesignTokens.space4,
            left: DesignTokens.space6,
            right: DesignTokens.space6,
            bottom: DesignTokens.space6 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Select Subject to Start Session',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'No active sessions found. Choose a subject to start a new session and begin scanning.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.space4),
              if (snapshot.connectionState == ConnectionState.waiting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.space6),
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                )
              else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.space6),
                  child: Column(
                    children: [
                      Icon(Icons.subject_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: DesignTokens.space3),
                      Text(
                        'No subjects available',
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        'Create a subject first from the Subjects tab',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final subject = snapshot.data![index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(DesignTokens.space2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                          ),
                          child: Icon(Icons.subject_rounded, color: colorScheme.primary, size: 24),
                        ),
                        title: Text(
                          subject.name,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          '${subject.code} - Section ${subject.section}',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        onTap: () => onSubjectSelected(subject.id!),
                        trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                      );
                    },
                  ),
                ),
              const SizedBox(height: DesignTokens.space4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.space3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
                  ),
                  child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet for selecting a session when multiple active sessions exist
class _SessionPickerBottomSheet extends ConsumerWidget {
  final List<Session> sessions;
  final void Function(Session session) onSessionSelected;

  const _SessionPickerBottomSheet({required this.sessions, required this.onSessionSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet)),
      ),
      padding: EdgeInsets.only(
        top: DesignTokens.space4,
        left: DesignTokens.space6,
        right: DesignTokens.space6,
        bottom: DesignTokens.space6 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Select Active Session',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            '${sessions.length} active sessions found. Choose one to start scanning.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sessions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(DesignTokens.space2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B8A3A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: Color(0xFF1B8A3A), size: 24),
                  ),
                  title: Text(
                    'Subject ${session.subjectId}',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '${session.date} • ${session.startTime} - ${session.endTime}',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  onTap: () => onSessionSelected(session),
                  trailing: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1B8A3A), size: 24),
                );
              },
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
              ),
              child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}