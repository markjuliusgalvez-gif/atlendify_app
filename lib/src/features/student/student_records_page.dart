import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart'
    show DesignTokens;
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class StudentRecordsPage extends ConsumerStatefulWidget {
  const StudentRecordsPage({super.key});

  @override
  ConsumerState<StudentRecordsPage> createState() => _StudentRecordsPageState();
}

class _StudentRecordsPageState extends ConsumerState<StudentRecordsPage> {
  int _selectedIndex = 1;
  String? _selectedStatus;
  String? _searchQuery;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.studentHome);
        break;
      case 1:
        // Records - already here
        break;
      case 2:
        context.go(AppRoutes.studentProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: true,
      body: session != null
          ? _buildRecordsContent(session, colorScheme, textTheme)
          : Center(
              child: Text(
                'Not logged in',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
      bottomNavigationBar: _buildGlassNavBar(colorScheme),
    );
  }

  Widget _buildGlassNavBar(ColorScheme colorScheme) {
    return GlassNavBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded),
          label: 'My Records',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
      isDark: Theme.of(context).brightness == Brightness.dark,
      accentColor: colorScheme.primary,
    );
  }

  Widget _buildRecordsContent(UserSession session, ColorScheme colorScheme, TextTheme textTheme) {
    return SafeArea(
      top: true,
      child: Column(
        children: [
          // Header
          _buildRecordsHeader(colorScheme, textTheme),
          // Records list
          Expanded(
            child: FutureBuilder<List<Attendance>>(
              future: _fetchAttendance(session.student!.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: DesignTokens.space4),
                        Text(
                          'Loading records...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return ErrorState(
                    message: snapshot.error.toString(),
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    onRetry: () => setState(() {}),
                  );
                }

                final records = snapshot.data ?? [];
                final filteredRecords = _applyFilters(records);

                if (filteredRecords.isEmpty) {
                  return _buildEmptyState(colorScheme, textTheme);
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: colorScheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space6,
                      DesignTokens.space4,
                      DesignTokens.space6,
                      DesignTokens.space6 + 100,
                    ),
                    itemCount: filteredRecords.length,
                    separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space3),
                    itemBuilder: (context, index) {
                      final attendance = filteredRecords[index];
                      return _buildRecordCard(attendance, context, colorScheme, textTheme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Attendance>> _fetchAttendance(int studentId) async {
    final attendanceRepo = AttendanceRepository();
    return attendanceRepo.getByStudent(studentId);
  }

  List<Attendance> _applyFilters(List<Attendance> records) {
    return records.where((record) {
      if (_selectedStatus != null && record.status != _selectedStatus) {
        return false;
      }
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final dateStr = _formatTimestamp(record.scannedAt);
        if (!dateStr.contains(_searchQuery!)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRecordsHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space5,
        DesignTokens.space5,
        DesignTokens.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Records',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'View your attendance history',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
              ),
              child: Icon(
                Icons.history_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'No attendance records',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              _selectedStatus != null || _searchQuery != null
                  ? 'No records match your filters'
                  : 'Your attendance history will appear here',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedStatus != null || _searchQuery != null) ...[
              const SizedBox(height: DesignTokens.space6),
              PillButton(
                label: 'Clear Filters',
                icon: Icons.clear_all_rounded,
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _searchQuery = null;
                  });
                },
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Attendance attendance, BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (attendance.status) {
      case 'present':
        statusColor = const Color(0xFF1B8A3A);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Present';
        break;
      case 'late':
        statusColor = const Color(0xFFF5A623);
        statusIcon = Icons.access_time_rounded;
        statusLabel = 'Late';
        break;
      case 'absent':
        statusColor = const Color(0xFFD0021B);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Absent';
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = 'Unknown';
    }

    return SoftCard(
      isDark: Theme.of(context).brightness == Brightness.dark,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session on ${_formatTimestamp(attendance.scannedAt)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Marked at ${_formatTime(attendance.scannedAt)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3, vertical: DesignTokens.space1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  statusLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.space1),
              Text(
                'Source: ${attendance.source}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}