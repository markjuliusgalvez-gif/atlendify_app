import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class AdminRecordsPage extends ConsumerStatefulWidget {
  const AdminRecordsPage({super.key});

  @override
  ConsumerState<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends ConsumerState<AdminRecordsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  String? _selectedSubjectId;
  String? _selectedDate;
  String? _selectedStatus;
  String? _searchQuery;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
        // Records - already here
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: authState is AuthAuthenticated
          ? _buildRecordsContentWithHeader(textPrimary, textSecondary, isDark)
          : Center(
              child: Text(
                'Not logged in',
                style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterSheet,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        child: const Icon(Icons.filter_list_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildFloatingNavBar(isDark),
    );
  }

  Widget _buildRecordsContentWithHeader(Color textPrimary, Color textSecondary, bool isDark) {
    return FutureBuilder<List<Subject>>(
      future: _fetchSubjects(),
      builder: (context, snapshot) {
        final subjects = snapshot.data ?? [];

        return Column(
          children: [
            // Header with profile menu
            _buildRecordsHeader(textPrimary, textSecondary, isDark),
            // Filter chips bar
            _buildFilterBar(subjects, textPrimary, textSecondary, isDark),
            // Records list
            Expanded(
              child: FutureBuilder<List<AttendanceWithDetails>>(
                future: _fetchFilteredRecords(),
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

                  if (records.isEmpty) {
                    return _buildEmptyState(textPrimary, textSecondary, isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    color: BrandColors.primary,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            DesignTokens.space6,
                            DesignTokens.space4,
                            DesignTokens.space6,
                            DesignTokens.space6 + 120,
                          ),
                          itemCount: records.length,
                          separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space3),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return _buildRecordCard(record, isDark);
                          },
                        ),
                      ),
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
                  'Attendance Records',
                  style: DesignTokens.headlineMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Filter and view student attendance',
                  style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: DesignTokens.space2),
          _buildProfileMenu(textPrimary, textSecondary, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(Color textPrimary, Color textSecondary, {required bool isDark}) {
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
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
                  isDark: isDark,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: DesignTokens.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        session?.user.email ?? '',
                        style: DesignTokens.bodySmall.copyWith(
                          color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
              Icon(Icons.person_outline_rounded, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
              const SizedBox(width: DesignTokens.space2),
              Text('My Profile', style: DesignTokens.labelLarge),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_avatar',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
              const SizedBox(width: DesignTokens.space2),
              Text('Change Picture', style: DesignTokens.labelLarge),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: BrandColors.absentRed),
              const SizedBox(width: DesignTokens.space2),
              Text('Logout', style: DesignTokens.labelLarge.copyWith(color: BrandColors.absentRed)),
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
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
        child: AvatarCircle(
          name: user?.fullName,
          size: 36,
          isDark: isDark,
        ),
      ),
    );
  }

  void _showChangeAvatarDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
        title: Text(
          'Change Profile Picture',
          style: DesignTokens.headlineSmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This feature will be implemented soon. You can pick an image from gallery or camera.',
          style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: DesignTokens.labelLarge.copyWith(
                color: textSecondary,
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
              style: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
        title: Text(
          'Logout',
          style: DesignTokens.headlineSmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: DesignTokens.labelLarge.copyWith(
                color: textSecondary,
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
              backgroundColor: BrandColors.absentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
            ),
            child: Text(
              'Logout',
              style: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    return FloatingNavBar(
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
      isDark: isDark,
      accentColor: BrandColors.primary,
    );
  }

  Widget _buildFilterBar(List<Subject> subjects, Color textPrimary, Color textSecondary, bool isDark) {
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: outlineColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Subject filter - styled as small button
            _buildFilterButton(
              label: _selectedSubjectId != null
                  ? subjects.firstWhere((s) => s.id.toString() == _selectedSubjectId).name
                  : 'All Subjects',
              onTap: () => _showSubjectFilter(subjects),
              icon: Icons.subject_outlined,
              isDark: isDark,
              isActive: _selectedSubjectId != null,
            ),
            const SizedBox(width: DesignTokens.space2),
            // Date filter
            _buildFilterButton(
              label: _selectedDate != null ? _formatDateDisplay(_selectedDate!) : 'All Dates',
              onTap: _showDateFilter,
              icon: Icons.calendar_today_outlined,
              isDark: isDark,
              isActive: _selectedDate != null,
            ),
            const SizedBox(width: DesignTokens.space2),
            // Status filter
            _buildFilterButton(
              label: _selectedStatus != null ? _selectedStatus!.toUpperCase() : 'All Status',
              onTap: _showStatusFilter,
              icon: Icons.flag_outlined,
              color: _getStatusColor(_selectedStatus),
              isDark: isDark,
              isActive: _selectedStatus != null,
            ),
            const SizedBox(width: DesignTokens.space2),
            // Search
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
              child: _StyledSearchField(
                hintText: 'Search student...',
                searchQuery: _searchQuery,
                onChanged: (value) => setState(() => _searchQuery = value.isEmpty ? null : value),
                onClear: () => setState(() => _searchQuery = null),
                isDark: isDark,
              ),
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(width: DesignTokens.space2),
              _buildFilterButton(
                label: 'Clear All',
                onTap: _clearFilters,
                icon: Icons.clear_all_rounded,
                isDark: isDark,
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
    required bool isDark,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;
    final surfaceColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final primaryColor = color ?? BrandColors.primary;

    final bgColor = isActive || isDestructive
        ? (isDestructive ? BrandColors.absentRed.withValues(alpha: 0.12) : primaryColor.withValues(alpha: 0.12))
        : surfaceColor;
    final borderColor = isActive || isDestructive
        ? (isDestructive ? BrandColors.absentRed : primaryColor)
        : outlineColor;
    final textColor = isActive || isDestructive
        ? (isDestructive ? BrandColors.absentRed : primaryColor)
        : textSecondary;
    final iconColor = isActive || isDestructive
        ? (isDestructive ? BrandColors.absentRed : primaryColor)
        : textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space1,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: DesignTokens.space1),
            Text(
              label,
              style: DesignTokens.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

  void _showFilterSheet() async {
    final subjects = await _fetchSubjects();
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Records',
                            style: DesignTokens.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearFilters();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Clear All',
                              style: DesignTokens.labelLarge.copyWith(
                                color: BrandColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space4),
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
                        isDark: isDark,
                      ),
                      const SizedBox(height: DesignTokens.space3),
                      _buildFilterSection(
                        title: 'Date',
                        icon: Icons.calendar_today_outlined,
                        value: _selectedDate != null ? _formatDateDisplay(_selectedDate!) : 'All Dates',
                        onTap: _showDateFilter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: DesignTokens.space3),
                      _buildFilterSection(
                        title: 'Status',
                        icon: Icons.flag_outlined,
                        value: _selectedStatus != null ? _selectedStatus!.toUpperCase() : 'All Status',
                        onTap: _showStatusFilter,
                        color: _getStatusColor(_selectedStatus),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
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

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    Color? color,
    required bool isDark,
  }) {
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space2),
              decoration: BoxDecoration(
                color: (color ?? textPrimary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
              ),
              child: Icon(
                icon,
                color: color ?? textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: color ?? textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: textSecondary,
            ),
          ],
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
                Icons.assessment_outlined,
                size: 64,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'No records found',
              style: DesignTokens.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your filters'
                  : 'Attendance records will appear here',
              style: DesignTokens.bodyLarge.copyWith(
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: DesignTokens.space6),
              PillButton(
                label: 'Clear All Filters',
                icon: Icons.clear_all_rounded,
                onPressed: _clearFilters,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(AttendanceWithDetails record, bool isDark) {
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
                      record.student.fullName,
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${record.student.studentNumber} • ${record.subject?.name ?? 'Unknown Subject'}',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    _formatDateTime(record.attendance.scannedAt),
                    style: DesignTokens.bodySmall.copyWith(
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                    ),
                  ),
                ],
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
                'Source: ${record.attendance.source} • Session: ${record.session.date} ${record.session.startTime}-${record.session.endTime}',
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

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

class _StyledSearchField extends StatelessWidget {
  final String hintText;
  final String? searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;

  const _StyledSearchField({
    required this.hintText,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: DesignTokens.bodyMedium.copyWith(color: textSecondary.withValues(alpha: 0.6)),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: searchQuery != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClear,
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: BrandColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? BrandColors.darkBackground : BrandColors.lightBackground,
      ),
      style: DesignTokens.bodyMedium.copyWith(color: textPrimary),
      onChanged: onChanged,
    );
  }
}