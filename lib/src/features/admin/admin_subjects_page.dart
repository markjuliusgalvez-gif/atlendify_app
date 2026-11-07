import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class AdminSubjectsPage extends ConsumerStatefulWidget {
  const AdminSubjectsPage({super.key});

  @override
  ConsumerState<AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends ConsumerState<AdminSubjectsPage> {
  int _selectedIndex = 1;

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
        title: const Text('Subjects'),
        actions: [
          IconButton(
            onPressed: _showAddSubjectDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Subject',
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: authState is AuthAuthenticated
          ? _buildSubjectsList()
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

  Widget _buildSubjectsList() {
    return FutureBuilder<List<Subject>>(
      future: _fetchSubjects(),
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
                  'Failed to load subjects',
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

        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.subject_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 24),
                Text(
                  'No subjects yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add your first subject to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _showAddSubjectDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Subject'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return _buildSubjectCard(subject);
            },
          ),
        );
      },
    );
  }

  Future<List<Subject>> _fetchSubjects() async {
    final subjectRepo = SubjectRepository();
    return subjectRepo.getAll();
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.code} - Section ${subject.section}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      case 'delete':
                        _confirmDeleteSubject(subject);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'enroll',
                      child: Row(
                        children: [
                          Icon(Icons.people_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Manage Enrollment'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.calendar_today_rounded, subject.days),
                _buildInfoChip(Icons.access_time_rounded, '${subject.startTime} - ${subject.endTime}'),
                _buildInfoChip(Icons.schedule_rounded, 'Late after: ${subject.lateAfterTime}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
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
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g., Computer Science',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Subject name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Code',
                      hintText: 'e.g., CS101',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Subject code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: sectionController,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      hintText: 'e.g., A',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Section is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: daysController,
                    decoration: const InputDecoration(
                      labelText: 'Days',
                      hintText: 'e.g., Mon,Wed,Fri',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Days are required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: '08:00',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lateAfterTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Late After',
                            hintText: '08:15',
                          ),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      hintText: '10:00',
                    ),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
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
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"? This will also remove all sessions and enrollments for this subject.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final subjectRepo = SubjectRepository();
                await subjectRepo.delete(subject.id!);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subject deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text('Enrollment: ${widget.subject.name}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              '${_enrolledStudents.length} of ${_allStudents.length} students enrolled',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _allStudents.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = _allStudents[index];
                  final isEnrolled = _enrolledStudents.any((s) => s.id == student.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isEnrolled
                          ? BrandColors.presentGreen.withValues(alpha: 0.12)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isEnrolled ? Icons.check_rounded : Icons.person_outline_rounded,
                        color: isEnrolled ? BrandColors.presentGreen : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(student.fullName),
                    subtitle: Text(student.studentNumber),
                    trailing: Switch(
                      value: isEnrolled,
                      onChanged: (_) => _toggleEnrollment(student),
                    ),
                    onTap: () => _toggleEnrollment(student),
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
          child: const Text('Done'),
        ),
      ],
    );
  }
}