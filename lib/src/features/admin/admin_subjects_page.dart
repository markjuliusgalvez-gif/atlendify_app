import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class AdminSubjectsPage extends ConsumerStatefulWidget {
  const AdminSubjectsPage({super.key});

  @override
  ConsumerState<AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends ConsumerState<AdminSubjectsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
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
        // Subjects - already here
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
          ? _buildSubjectsContent(textPrimary, textSecondary, isDark)
          : Center(
              child: Text(
                'Not logged in',
                style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildFloatingNavBar(isDark),
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

  Widget _buildSubjectsContent(Color textPrimary, Color textSecondary, bool isDark) {
    return FutureBuilder<List<Subject>>(
      future: _fetchSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: BrandColors.primary),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Loading subjects...',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
                    color: BrandColors.absentRed,
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Failed to load subjects',
                    style: DesignTokens.headlineSmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    snapshot.error.toString(),
                    style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  PillButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: () => setState(() {}),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        }

        final subjects = snapshot.data ?? [];

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: BrandColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.space6,
                        DesignTokens.space6,
                        DesignTokens.space6,
                        DesignTokens.space4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subjects',
                                  style: DesignTokens.headlineLarge.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.space1),
                                Text(
                                  'Manage your course subjects',
                                  style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (subjects.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.space3,
                                vertical: DesignTokens.space1,
                              ),
                              decoration: BoxDecoration(
                                color: BrandColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                              ),
                              child: Text(
                                '${subjects.length} subject${subjects.length != 1 ? 's' : ''}',
                                style: DesignTokens.labelMedium.copyWith(
                                  color: BrandColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space6,
                      0,
                      DesignTokens.space6,
                      DesignTokens.space6 + 120,
                    ),
                    sliver: subjects.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(textPrimary, textSecondary, isDark),
                          )
                        : SliverList.separated(
                            itemCount: subjects.length,
                            separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space3),
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return _buildSubjectCard(subject, isDark, index);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space6),
              decoration: BoxDecoration(
                color: (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
              ),
              child: Icon(
                Icons.subject_outlined,
                size: 64,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'No subjects yet',
              style: DesignTokens.headlineSmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              'Add your first subject to get started',
              style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space6),
            PillButton(
              label: 'Add Subject',
              icon: Icons.add_rounded,
              onPressed: _showAddSubjectDialog,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
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
        isDark: isDark,
        padding: const EdgeInsets.all(DesignTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: DesignTokens.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        '${subject.code} - Section ${subject.section}',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditSubjectDialog(subject);
                        break;
                      case 'enroll':
                        _showEnrollmentDialog(subject);
                        break;
                      case 'dashboard':
                        context.push(AppRoutes.adminSubjectDashboard.replaceAll(':subjectId', subject.id.toString()));
                        break;
                      case 'delete':
                        _confirmDeleteSubject(subject);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'dashboard',
                      child: Row(
                        children: [
                          Icon(Icons.dashboard_outlined, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
                          const SizedBox(width: 8),
                          Text('Open Dashboard', style: DesignTokens.labelLarge),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
                          const SizedBox(width: 8),
                          Text('Edit', style: DesignTokens.labelLarge),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'enroll',
                      child: Row(
                        children: [
                          Icon(Icons.people_outlined, size: 20, color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
                          const SizedBox(width: 8),
                          Text('Manage Enrollment', style: DesignTokens.labelLarge),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: BrandColors.absentRed),
                          const SizedBox(width: 8),
                          Text('Delete', style: DesignTokens.labelLarge.copyWith(color: BrandColors.absentRed)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.space2),
                    decoration: BoxDecoration(
                      color: (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space3),
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: [
                _buildInfoChip(Icons.calendar_today_rounded, subject.days, isDark),
                _buildInfoChip(Icons.access_time_rounded, '${subject.startTime} - ${subject.endTime}', isDark),
                _buildInfoChip(Icons.schedule_rounded, 'Late after: ${subject.lateAfterTime}', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(
          color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary),
          const SizedBox(width: DesignTokens.space1),
          Text(
            label,
            style: DesignTokens.labelSmall.copyWith(
              color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Subject>> _fetchSubjects() async {
    final subjectRepo = SubjectRepository();
    return subjectRepo.getAll();
  }

  void _showAddSubjectDialog() {
    _showSubjectDialog();
  }

  void _showEditSubjectDialog(Subject subject) {
    _showSubjectDialog(subject: subject);
  }

  void _showSubjectDialog({Subject? subject}) {
    final isEditing = subject != null;
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    final sectionController = TextEditingController(text: subject?.section ?? '');
    final daysController = TextEditingController(text: subject?.days ?? '');
    final startTimeController = TextEditingController(text: subject?.startTime ?? '');
    final lateAfterTimeController = TextEditingController(text: subject?.lateAfterTime ?? '');
    final endTimeController = TextEditingController(text: subject?.endTime ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => _StyledSubjectDialog(
        isEditing: isEditing,
        formKey: formKey,
        nameController: nameController,
        codeController: codeController,
        sectionController: sectionController,
        daysController: daysController,
        startTimeController: startTimeController,
        lateAfterTimeController: lateAfterTimeController,
        endTimeController: endTimeController,
        onSave: () async {
          if (!formKey.currentState!.validate()) return;

          final now = DateTime.now().millisecondsSinceEpoch;
          final subjectRepo = SubjectRepository();

          final newSubject = Subject(
            id: subject?.id,
            name: nameController.text.trim(),
            code: codeController.text.trim(),
            section: sectionController.text.trim(),
            days: daysController.text.trim(),
            startTime: startTimeController.text.trim(),
            lateAfterTime: lateAfterTimeController.text.trim(),
            endTime: endTimeController.text.trim(),
            createdAt: subject?.createdAt ?? now,
            updatedAt: now,
          );

          try {
            if (isEditing) {
              await subjectRepo.update(newSubject);
            } else {
              await subjectRepo.insert(newSubject);
            }
            if (mounted) {
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Subject updated' : 'Subject created'),
                  backgroundColor: BrandColors.presentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: BrandColors.absentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEnrollmentDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => _EnrollmentDialog(subject: subject),
    );
  }

  void _confirmDeleteSubject(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => _StyledDeleteDialog(subject: subject, onDelete: () async {
        Navigator.pop(context);
        try {
          final subjectRepo = SubjectRepository();
          await subjectRepo.delete(subject.id!);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Subject deleted'),
                backgroundColor: BrandColors.presentGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: BrandColors.absentRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                ),
              ),
            );
          }
        }
      }),
    );
  }
}

class _StyledSubjectDialog extends StatelessWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController sectionController;
  final TextEditingController daysController;
  final TextEditingController startTimeController;
  final TextEditingController lateAfterTimeController;
  final TextEditingController endTimeController;
  final Future<void> Function() onSave;

  const _StyledSubjectDialog({
    required this.isEditing,
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.sectionController,
    required this.daysController,
    required this.startTimeController,
    required this.lateAfterTimeController,
    required this.endTimeController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    return AlertDialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        side: BorderSide(color: outlineColor, width: 1),
      ),
      title: Text(
        isEditing ? 'Edit Subject' : 'Add Subject',
        style: DesignTokens.headlineSmall.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StyledTextField(
                  controller: nameController,
                  label: 'Subject Name',
                  hint: 'e.g., Computer Science',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subject name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.space4),
                _StyledTextField(
                  controller: codeController,
                  label: 'Subject Code',
                  hint: 'e.g., CS101',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subject code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.space4),
                _StyledTextField(
                  controller: sectionController,
                  label: 'Section',
                  hint: 'e.g., A',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Section is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.space4),
                _StyledTextField(
                  controller: daysController,
                  label: 'Days',
                  hint: 'e.g., Mon,Wed,Fri',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Days are required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.space4),
                Row(
                  children: [
                    Expanded(
                      child: _StyledTextField(
                        controller: startTimeController,
                        label: 'Start Time',
                        hint: '08:00',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: _StyledTextField(
                        controller: lateAfterTimeController,
                        label: 'Late After',
                        hint: '08:15',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                _StyledTextField(
                  controller: endTimeController,
                  label: 'End Time',
                  hint: '10:00',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'End time is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
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
          onPressed: () => onSave(),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
          child: Text(
            isEditing ? 'Save' : 'Create',
            style: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: DesignTokens.bodyMedium.copyWith(color: textSecondary),
        hintStyle: DesignTokens.bodyMedium.copyWith(color: textSecondary.withValues(alpha: 0.6)),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: BrandColors.absentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: BrandColors.absentRed, width: 2),
        ),
        filled: true,
        fillColor: isDark ? BrandColors.darkBackground : BrandColors.lightBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
      style: DesignTokens.bodyMedium.copyWith(color: textPrimary),
      validator: validator,
    );
  }
}

class _StyledDeleteDialog extends StatelessWidget {
  final Subject subject;
  final VoidCallback onDelete;

  const _StyledDeleteDialog({
    required this.subject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    return AlertDialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        side: BorderSide(color: outlineColor, width: 1),
      ),
      title: Text(
        'Delete Subject',
        style: DesignTokens.headlineSmall.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${subject.name}"? This will also remove all sessions and enrollments for this subject.',
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
          onPressed: onDelete,
          style: FilledButton.styleFrom(
            backgroundColor: BrandColors.absentRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
          child: Text(
            'Delete',
            style: DesignTokens.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
    );
  }
}

class _EnrollmentDialog extends ConsumerStatefulWidget {
  final Subject subject;

  const _EnrollmentDialog({required this.subject});

  @override
  ConsumerState<_EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends ConsumerState<_EnrollmentDialog> {
  List<Student> _allStudents = [];
  List<Student> _enrolledStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final studentRepo = StudentRepository();
    final enrollmentRepo = SubjectStudentRepository();

    final all = await studentRepo.getAll();
    final enrolled = await enrollmentRepo.getEnrolledStudents(widget.subject.id!);

    if (mounted) {
      setState(() {
        _allStudents = all;
        _enrolledStudents = enrolled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEnrollment(Student student) async {
    final enrollmentRepo = SubjectStudentRepository();
    final isEnrolled = _enrolledStudents.any((s) => s.id == student.id);

    try {
      if (isEnrolled) {
        await enrollmentRepo.unenroll(widget.subject.id!, student.id!);
      } else {
        await enrollmentRepo.enroll(widget.subject.id!, student.id!);
      }
      await _loadStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: BrandColors.absentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    if (_isLoading) {
      return AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: outlineColor, width: 1),
        ),
        content: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
        side: BorderSide(color: outlineColor, width: 1),
      ),
      title: Text(
        'Enrollment: ${widget.subject.name}',
        style: DesignTokens.headlineSmall.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              '${_enrolledStudents.length} of ${_allStudents.length} students enrolled',
              style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
            ),
            const SizedBox(height: DesignTokens.space4),
            Expanded(
              child: ListView.separated(
                itemCount: _allStudents.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: DesignTokens.space4,
                  endIndent: DesignTokens.space4,
                  color: outlineColor,
                ),
                itemBuilder: (context, index) {
                  final student = _allStudents[index];
                  final isEnrolled = _enrolledStudents.any((s) => s.id == student.id);

                  return InkWell(
                    onTap: () => _toggleEnrollment(student),
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
                              color: isEnrolled
                                  ? BrandColors.presentGreen.withValues(alpha: 0.12)
                                  : (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                            ),
                            child: Icon(
                              isEnrolled ? Icons.check_rounded : Icons.person_outline_rounded,
                              color: isEnrolled ? BrandColors.presentGreen : textSecondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.fullName,
                                  style: DesignTokens.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  student.studentNumber,
                                  style: DesignTokens.bodySmall.copyWith(color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isEnrolled,
                            onChanged: (_) => _toggleEnrollment(student),
                            activeColor: BrandColors.presentGreen,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Done',
            style: DesignTokens.labelLarge.copyWith(
              color: BrandColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
    );
  }
}