import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _selectedIndex = 0;

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
        context.go(AppRoutes.adminScan);
        break;
      case 3:
        context.go(AppRoutes.adminRecords);
        break;
      case 4:
        context.go(AppRoutes.adminSettings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [const ThemeToggleButton()],
      ),
      body: authState is AuthAuthenticated
          ? _buildDashboardContent()
          : const Center(child: Text('Not logged in')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.subject_outlined),
            selectedIcon: Icon(Icons.subject),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(stats, context),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Recent sessions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.adminRecords),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRecentSessions(context),
              ],
            ),
          ),
        );
      },
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

    // Get today's attendance counts
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

  Widget _buildStatsGrid(Map<String, dynamic> stats, BuildContext context) {
    final items = [
      _StatItem('Subjects', stats['totalSubjects'].toString(), Icons.subject_rounded, BrandColors.primary),
      _StatItem('Students', stats['totalStudents'].toString(), Icons.people_rounded, BrandColors.primaryLight),
      _StatItem('Active Sessions', stats['activeSessions'].toString(), Icons.event_rounded, BrandColors.presentGreen),
      _StatItem('Today\'s Sessions', stats['todaySessions'].toString(), Icons.today_rounded, BrandColors.lateAmber),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
              child: _buildStatCard(item, context),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatItem item, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 24,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
            Text(
              item.value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        'New Session',
        Icons.add_circle_outline_rounded,
        BrandColors.primary,
        () => context.go(AppRoutes.adminSubjects),
      ),
      _QuickAction(
        'Start Scan',
        Icons.qr_code_scanner_rounded,
        BrandColors.presentGreen,
        () => context.go(AppRoutes.adminScan),
      ),
      _QuickAction(
        'View Records',
        Icons.assessment_outlined,
        BrandColors.lateAmber,
        () => context.go(AppRoutes.adminRecords),
      ),
      _QuickAction(
        'Manage Subjects',
        Icons.subject_outlined,
        BrandColors.primaryLight,
        () => context.go(AppRoutes.adminSubjects),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
              child: _buildActionCard(action, context),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionCard(_QuickAction action, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                action.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessions(BuildContext context) {
    return FutureBuilder<List<Session>>(
      future: _fetchRecentSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent sessions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a session from the Subjects tab',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final sessions = snapshot.data!.take(5).toList();

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.event_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  'Session ${session.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  '${session.date} • ${session.startTime} - ${session.endTime}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: Chip(
                  label: Text(
                    session.status == 'open' ? 'Open' : 'Closed',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: session.status == 'open'
                      ? BrandColors.presentGreen.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: session.status == 'open'
                        ? BrandColors.presentGreen
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => context.go('${AppRoutes.adminRecords}?sessionId=${session.id}'),
              );
            },
          ),
        );
      },
    );
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