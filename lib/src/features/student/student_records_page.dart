import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class StudentRecordsPage extends ConsumerStatefulWidget {
  const StudentRecordsPage({super.key});

  @override
  ConsumerState<StudentRecordsPage> createState() => _StudentRecordsPageState();
}

class _StudentRecordsPageState extends ConsumerState<StudentRecordsPage> with TickerProviderStateMixin {
  int _selectedIndex = 1;
  String? _selectedStatus;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
  }

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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(context),
    );
  }

  Widget _buildFilterSheet(BuildContext context) {
    final statusOptions = [
      {'value': null, 'label': 'All Status', 'color': null},
      {'value': 'present', 'label': 'Present', 'color': BrandColors.presentGreen},
      {'value': 'late', 'label': 'Late', 'color': BrandColors.lateAmber},
      {'value': 'absent', 'label': 'Absent', 'color': BrandColors.absentRed},
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.6,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Records',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = null;
                            _searchQuery = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statusOptions.map((option) {
                      final isSelected = _selectedStatus == option['value'];
                      final color = option['color'] as Color?;
                      return FilterChip(
                        label: Text(option['label'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? option['value'] as String? : null;
                          });
                          Navigator.pop(context);
                        },
                        selectedColor: color?.withValues(alpha: 0.2) ?? Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? (color ?? Theme.of(context).colorScheme.onPrimaryContainer) : null,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected ? (color ?? Theme.of(context).colorScheme.primary) : Theme.of(context).colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Search',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by subject, date...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = null);
                                Navigator.pop(context);
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value.isEmpty ? null : value);
                      Navigator.pop(context);
                    },
                    autofocus: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Records'),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: session != null
          ? _buildRecordsContent(session)
          : const Center(child: Text('Not logged in')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'My Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsContent(UserSession session) {
    return FutureBuilder<List<Attendance>>(
      future: _fetchAttendance(session.student!.id!),
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
                  'Failed to load records',
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

        final records = snapshot.data ?? [];
        final filteredRecords = _applyFilters(records);

        if (filteredRecords.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRecords.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final attendance = filteredRecords[index];
              return _buildRecordCard(attendance, context);
            },
          ),
        );
      },
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
        // In a real app, you'd search by session/subject name
        // For now, we'll just check the date
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No attendance records',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedStatus != null || _searchQuery != null
                  ? 'No records match your filters'
                  : 'Your attendance history will appear here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (_selectedStatus != null || _searchQuery != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _searchQuery = null;
                  });
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Attendance attendance, BuildContext context) {
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
        statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = 'Unknown';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session on ${_formatTimestamp(attendance.scannedAt)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Marked at ${_formatTime(attendance.scannedAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Source: ${attendance.source}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}