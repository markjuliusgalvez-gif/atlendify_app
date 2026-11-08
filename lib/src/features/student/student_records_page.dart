import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: session != null
          ? _buildRecordsContent(session, textPrimary, textSecondary, isDark)
          : Center(
              child: Text(
                'Not logged in',
                style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              ),
            ),
      bottomNavigationBar: _buildFloatingNavBar(isDark),
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    return FloatingNavBar(
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
      isDark: isDark,
      accentColor: BrandColors.primary,
    );
  }

  Widget _buildRecordsContent(UserSession session, Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      children: [
        // Header
        _buildRecordsHeader(textPrimary, textSecondary, isDark),
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
                      CircularProgressIndicator(color: BrandColors.primary),
                      const SizedBox(height: DesignTokens.space4),
                      Text(
                        'Loading records...',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return ErrorState(
                  message: snapshot.error.toString(),
                  isDark: isDark,
                  onRetry: () => setState(() {}),
                );
              }

              final records = snapshot.data ?? [];
              final filteredRecords = _applyFilters(records);

              if (filteredRecords.isEmpty) {
                return _buildEmptyState(textPrimary, textSecondary, isDark);
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                color: BrandColors.primary,
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
                    return _buildRecordCard(attendance, context, isDark);
                  },
                ),
              );
            },
          ),
        ),
      ],
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

  Widget _buildRecordsHeader(Color textPrimary, Color textSecondary, bool isDark) {
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
                  style: DesignTokens.headlineMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'View your attendance history',
                  style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space6),
              decoration: BoxDecoration(
                color: (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
              ),
              child: Icon(
                Icons.history_outlined,
                size: 64,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'No attendance records',
              style: DesignTokens.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              _selectedStatus != null || _searchQuery != null
                  ? 'No records match your filters'
                  : 'Your attendance history will appear here',
              style: DesignTokens.bodyLarge.copyWith(
                color: textSecondary,
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
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Attendance attendance, BuildContext context, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (attendance.status) {
      case 'present':
        statusColor = BrandColors.presentGreen;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Present';
        break;
      case 'late':
        statusColor = BrandColors.lateAmber;
        statusIcon = Icons.access_time_rounded;
        statusLabel = 'Late';
        break;
      case 'absent':
        statusColor = BrandColors.absentRed;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Absent';
        break;
      default:
        statusColor = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = 'Unknown';
    }

    return SoftCard(
      isDark: isDark,
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
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Marked at ${_formatTime(attendance.scannedAt)}',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
                  style: DesignTokens.labelLarge.copyWith(
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
                color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
              ),
              const SizedBox(width: DesignTokens.space1),
              Text(
                'Source: ${attendance.source}',
                style: DesignTokens.bodySmall.copyWith(
                  color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}