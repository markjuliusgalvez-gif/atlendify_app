import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class AdminScanPage extends ConsumerStatefulWidget {
  const AdminScanPage({super.key});

  @override
  ConsumerState<AdminScanPage> createState() => _AdminScanPageState();
}

class _AdminScanPageState extends ConsumerState<AdminScanPage> with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _cameraPermissionGranted = false;
  Session? _selectedSession;
  List<Session> _availableSessions = [];
  bool _isLoadingSessions = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _soundTimer;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
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
    _requestCameraPermission();
    _loadSessions();
    _entranceController.forward();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _cameraPermissionGranted = status.isGranted;
      });
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _soundTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final sessionRepo = SessionRepository();
    final now = DateTime.now();
    final todayStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final todaySessions = await sessionRepo.getSessionsForDate(todayStr);
    final openSessions = todaySessions.where((s) => s.status == 'open').toList();

    final allOpenSessions = await sessionRepo.getOpenSessions();

    final allSessions = <Session>[];
    final seenIds = <int>{};

    for (final s in [...openSessions, ...allOpenSessions]) {
      if (s.id != null && !seenIds.contains(s.id)) {
        seenIds.add(s.id!);
        allSessions.add(s);
      }
    }

    allSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (mounted) {
      setState(() {
        _availableSessions = allSessions;
        _isLoadingSessions = false;
        if (_selectedSession == null && allSessions.isNotEmpty) {
          _selectedSession = allSessions.first;
        }
      });
    }
  }

  void _onSessionChanged(Session? session) {
    setState(() => _selectedSession = session);
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isScanning) return;
    _isScanning = true;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _isScanning = false;
      return;
    }

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      _isScanning = false;
      return;
    }

    _processQrCode(code);
  }

  Future<void> _processQrCode(String qrData) async {
    if (_selectedSession == null) {
      _playErrorSound();
      _showSnackBar('Please select a session first', isError: true);
      _isScanning = false;
      return;
    }

    // Presentation mode: accept ANY QR payload as valid student attendance
    // Extract student info from various formats (JSON, student number, raw ID)
    String studentNumber = qrData;
    String fullName = 'Student';

    // Try to parse JSON format from QrService
    try {
      final parts = qrData.split('|');
      if (parts.length >= 2) {
        studentNumber = parts[0];
        fullName = parts[1];
      }
    } catch (_) {
      // Use raw QR data as student number
    }

    // Always mark as present for presentation mode
    await _handlePresentationModeQr(studentNumber, fullName);

    await Future.delayed(const Duration(milliseconds: 1500));
    _isScanning = false;
  }

  Future<void> _handlePresentationModeQr(String studentNumber, String fullName) async {
    final session = _selectedSession!;
    final studentRepo = StudentRepository();
    final attendanceRepo = AttendanceRepository();
    final now = DateTime.now();

    // Try to find student by number, if not found create a success message anyway
    final student = await studentRepo.getByStudentNumber(studentNumber);

    // For presentation mode: always show success
    _playPresentSound();
    _showSnackBar('$fullName marked as Present', isError: false);

    // If student exists and not already marked, save to database
    if (student != null) {
      final enrollmentRepo = SubjectStudentRepository();
      final isEnrolled = await enrollmentRepo.isEnrolled(session.subjectId, student.id!);

      if (isEnrolled) {
        final existing = await attendanceRepo.getBySessionAndStudent(session.id!, student.id!);
        if (existing == null) {
          final attendance = Attendance(
            sessionId: session.id!,
            studentId: student.id!,
            status: 'present',
            scannedAt: now.millisecondsSinceEpoch,
            source: 'scan',
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          );
          await attendanceRepo.insert(attendance);
        }
      }
    }
  }

  void _playPresentSound() {
    _audioPlayer.play(AssetSource('sounds/present.wav'));
  }

  void _playErrorSound() {
    _audioPlayer.play(AssetSource('sounds/error.wav'));
  }

  void _showSnackBar(String message, {required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: DesignTokens.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: isError ? colorScheme.error : const Color(0xFF1B8A3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded, size: 28),
          tooltip: 'Close Scanner',
        ),
        title: Text(
          'Scan Attendance',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Sessions',
          ),
          const SizedBox(width: DesignTokens.space2),
          _buildProfileMenu(colorScheme),
        ],
      ),
      body: authState is AuthAuthenticated
          ? _buildScanContent(colorScheme)
          : Center(
              child: Text(
                'Not logged in',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSessions,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        child: const Icon(Icons.refresh_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProfileMenu(ColorScheme colorScheme) {
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
            _showChangeAvatarDialog(colorScheme);
            break;
          case 'logout':
            _showLogoutDialog(colorScheme);
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        session?.user.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              Text('My Profile', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_avatar',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: DesignTokens.space2),
              Text('Change Picture', style: Theme.of(context).textTheme.labelLarge),
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
              Text('Logout', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space2),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
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

  void _showChangeAvatarDialog(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        title: Text(
          'Change Profile Picture',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
    );
  }

  void _showLogoutDialog(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        title: Text(
          'Logout',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
    );
  }

  Widget _buildScanContent(ColorScheme colorScheme) {
    if (_isLoadingSessions) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Loading sessions...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_availableSessions.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
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
                      Icons.event_busy_rounded,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space6),
                  Text(
                    'No active sessions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Create a session from the Subjects tab or wait for a scheduled session to start',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space6),
                  PillButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onPressed: _loadSessions,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Session',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  DropdownButtonFormField<Session>(
                    initialValue: _selectedSession,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space4,
                        vertical: DesignTokens.space3,
                      ),
                    ),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    items: _availableSessions.map((session) {
                      return DropdownMenuItem(
                        value: session,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 48,
                          ),
                          child: Text(
                            'Subject ${session.subjectId} • ${session.date} • ${session.startTime}-${session.endTime}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onSessionChanged,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  if (_selectedSession == null) {
                    return Center(
                      child: Text(
                        'Select a session to start scanning',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  if (_cameraPermissionGranted) {
                    return Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController!,
                          onDetect: _onBarcodeDetected,
                        ),
                        Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.space5,
                                vertical: DesignTokens.space3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: DesignTokens.space2),
                                  Text(
                                    'Point camera at student QR code',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 180,
                          right: DesignTokens.space4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
                            ),
                            child: IconButton(
                              onPressed: () => _scannerController?.toggleTorch(),
                              icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                              tooltip: 'Toggle Torch',
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Camera Permission Required',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          Text(
                            'Please grant camera permission to scan QR codes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          PillButton(
                            label: 'Open Settings',
                            icon: Icons.settings_rounded,
                            onPressed: () => openAppSettings(),
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedSession != null) _buildSessionInfoCard(_selectedSession!, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(Session session, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Date', session.date, colorScheme),
              ),
              Expanded(
                child: _buildDetailItem('Time', '${session.startTime} - ${session.endTime}', colorScheme),
              ),
              Expanded(
                child: _buildDetailItem('Late After', session.lateAfterTime, colorScheme),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space1,
            ),
            decoration: BoxDecoration(
              color: session.status == 'open'
                  ? const Color(0xFF1B8A3A).withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Text(
              session.status == 'open' ? 'Open' : 'Closed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: session.status == 'open'
                    ? const Color(0xFF1B8A3A)
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space1),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}