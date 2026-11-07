import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class AdminRecordsPage extends ConsumerStatefulWidget {
  const AdminRecordsPage({super.key});

  @override
  ConsumerState<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends ConsumerState<AdminRecordsPage> {
  int _selectedIndex = 3;
  String? _selectedSubjectId;
  String? _selectedDate;
  String? _selectedStatus;
  String? _searchQuery;
  bool _isLoading = false;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.adminHome);
        break;
      case 1:
        context.go(AppRoutes.adminSubjects);
        break;
      case 2:
        context.go(AppRoutes.adminScan);
        break;
      case 3:
        // Records - already here
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
        title: const Text('Records'),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
          ),
          IconButton(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: authState is AuthAuthenticated
          ? _buildRecordsContent()
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

  Widget _buildRecordsContent() {
    return FutureBuilder<List<Subject>>(
      future: _fetchSubjects(),
      builder: (context, snapshot) {
        final subjects = snapshot.data ?? [];

        return Column(
          children: [
            // Filter chips bar
            _buildFilterBar(subjects),
            // Records list
            Expanded(
              child: FutureBuilder<List<AttendanceWithDetails>>(
                future: _fetchFilteredRecords(),
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

                  if (records.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _buildRecordCard(record);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(List<Subject> subjects) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: Row(
            children: [
              // Subject filter
              _buildFilterChip(
                label: _selectedSubjectId != null
                    ? subjects.firstWhere((s) => s.id.toString() == _selectedSubjectId).name
                    : 'All Subjects',
                onTap: () => _showSubjectFilter(subjects),
                icon: Icons.subject_outlined,
              ),
              const SizedBox(width: 8),
              // Date filter
              _buildFilterChip(
                label: _selectedDate != null ? _formatDateDisplay(_selectedDate!) : 'All Dates',
                onTap: _showDateFilter,
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(width: 8),
              // Status filter
              _buildFilterChip(
                label: _selectedStatus != null ? _selectedStatus!.toUpperCase() : 'All Status',
                onTap: _showStatusFilter,
                icon: Icons.flag_outlined,
                color: _getStatusColor(_selectedStatus),
              ),
              const SizedBox(width: 8),
              // Search
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search student...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() => _searchQuery = null);
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.isEmpty ? null : value),
                ),
              ),
              if (_hasActiveFilters()) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedSubjectId != null ||
        _selectedDate != null ||
        _selectedStatus != null ||
        _searchQuery != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedSubjectId = null;
      _selectedDate = null;
      _selectedStatus = null;
      _searchQuery = null;
    });
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
      label: Text(label, style: TextStyle(fontSize: 13)),
      onPressed: onTap,
      backgroundColor: color?.withValues(alpha: 0.12),
      side: BorderSide(color: color ?? Theme.of(context).colorScheme.outline),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  void _showFilterSheet() async {
    final subjects = await _fetchSubjects();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => SafeArea(
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
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
                              _clearFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Subject filter section
                      _buildFilterSection(
                        title: 'Subject',
                        icon: Icons.subject_outlined,
                        value: _selectedSubjectId != null
                            ? subjects.firstWhere((s) => s.id.toString() == _selectedSubjectId).name
                            : 'All Subjects',
                        onTap: () {
                          Navigator.pop(context);
                          _showSubjectFilter(subjects);
                        },
                      ),
                      const Divider(),
                      // Date filter
                      _buildFilterSection(
                        title: 'Date',
                        icon: Icons.calendar_today_outlined,
                        value: _selectedDate != null ? _formatDateDisplay(_selectedDate!) : 'All Dates',
                        onTap: _showDateFilter,
                      ),
                      const Divider(),
                      // Status filter
                      _buildFilterSection(
                        title: 'Status',
                        icon: Icons.flag_outlined,
                        value: _selectedStatus != null ? _selectedStatus!.toUpperCase() : 'All Status',
                        onTap: _showStatusFilter,
                        color: _getStatusColor(_selectedStatus),
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _clearFilters();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('Clear All Filters'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectFilter(List<Subject> subjects) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Subjects'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedSubjectId,
                onChanged: (value) {
                  if (mounted) {
                    setState(() => _selectedSubjectId = value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const Divider(),
            for (final subject in subjects)
              ListTile(
                title: Text(subject.name),
                subtitle: Text('${subject.code} - Section ${subject.section}'),
                leading: Radio<String?>(
                  value: subject.id.toString(),
                  groupValue: _selectedSubjectId,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _selectedSubjectId = value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDateFilter() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null ? DateTime.parse(_selectedDate!) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Status'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            ...[
              {'value': 'present', 'label': 'Present', 'color': BrandColors.presentGreen},
              {'value': 'late', 'label': 'Late', 'color': BrandColors.lateAmber},
              {'value': 'absent', 'label': 'Absent', 'color': BrandColors.absentRed},
            ].map((option) => ListTile(
                  title: Text(option['label'] as String),
                  leading: Radio<String?>(
                    value: option['value'] as String?,
                    groupValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      Navigator.pop(context);
                    },
                  ),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: option['color'] as Color,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDateDisplay(String dateStr) {
    if (dateStr.length != 8) return dateStr;
    return '${dateStr.substring(6, 8)}/${dateStr.substring(4, 6)}/${dateStr.substring(0, 4)}';
  }

  Color? _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return BrandColors.presentGreen;
      case 'late':
        return BrandColors.lateAmber;
      case 'absent':
        return BrandColors.absentRed;
      default:
        return null;
    }
  }

  Future<List<Subject>> _fetchSubjects() async {
    final subjectRepo = SubjectRepository();
    return subjectRepo.getAll();
  }

  Future<List<AttendanceWithDetails>> _fetchFilteredRecords() async {
    final attendanceRepo = AttendanceRepository();

    int? subjectId;
    if (_selectedSubjectId != null) {
      subjectId = int.tryParse(_selectedSubjectId!);
    }

    final records = await attendanceRepo.search(
      subjectId: subjectId,
      date: _selectedDate,
      status: _selectedStatus,
      studentName: _searchQuery,
    );

    // Enrich with student and session details
    final studentRepo = StudentRepository();
    final sessionRepo = SessionRepository();
    final subjectRepo = SubjectRepository();

    final enriched = <AttendanceWithDetails>[];

    for (final record in records) {
      final student = await studentRepo.getById(record.studentId);
      final session = await sessionRepo.getById(record.sessionId);
      Subject? subject;
      if (session != null) {
        subject = await subjectRepo.getById(session.subjectId);
      }

      if (student != null && session != null) {
        enriched.add(AttendanceWithDetails(
          attendance: record,
          student: student,
          session: session,
          subject: subject,
        ));
      }
    }

    return enriched;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No records found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your filters'
                  : 'Attendance records will appear here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear All Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(AttendanceWithDetails record) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (record.attendance.status) {
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
                        record.student.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${record.student.studentNumber} • ${record.subject?.name ?? 'Unknown Subject'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(record.attendance.scannedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
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
                  'Source: ${record.attendance.source} • Session: ${record.session.date} ${record.session.startTime}-${record.session.endTime}',
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

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _exportCsv() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final records = await _fetchFilteredRecords();

      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records to export')),
          );
        }
        return;
      }

      final csv = _generateCsv(records);
      final fileName = 'attendance_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      // For now, just show the CSV in a dialog (in real app, use share_plus or path_provider to save)
      if (mounted) {
        _showCsvDialog(csv, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateCsv(List<AttendanceWithDetails> records) {
    final buffer = StringBuffer();
    buffer.writeln('Student Number,Student Name,Subject,Section,Date,Session Time,Status,Scanned At,Source');

    for (final record in records) {
      final scannedAt = DateTime.fromMillisecondsSinceEpoch(record.attendance.scannedAt);
      buffer.writeln(
        '"${record.student.studentNumber}",'
        '"${record.student.fullName}",'
        '"${record.subject?.name ?? ''}",'
        '"${record.subject?.section ?? ''}",'
        '"${record.session.date}",'
        '"${record.session.startTime}-${record.session.endTime}",'
        '"${record.attendance.status}",'
        '"${DateFormat('yyyy-MM-dd HH:mm:ss').format(scannedAt)}",'
        '"${record.attendance.source}"'
      );
    }

    return buffer.toString();
  }

  void _showCsvDialog(String csv, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text('Export CSV')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$fileName (${csv.split('\n').length - 1} records)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              // In a real app, use share_plus or save to downloads
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV export ready (implement save/share in production)')),
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class AttendanceWithDetails {
  final Attendance attendance;
  final Student student;
  final Session session;
  final Subject? subject;

  AttendanceWithDetails({
    required this.attendance,
    required this.student,
    required this.session,
    this.subject,
  });
}