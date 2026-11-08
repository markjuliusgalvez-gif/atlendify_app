import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/status_rules.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
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
      _showSnackBar('Please select a session first');
      _isScanning = false;
      return;
    }

    final now = DateTime.now();
    final result = QrService.verifyQr(qrData, now);

    switch (result) {
      case ValidQrResult():
        await _handleValidQr(result.studentNumber, result.fullName);
        break;
      case OldCodeQrResult():
        _playLateSound();
        _showSnackBar('${result.message} (${result.fullName})');
        break;
      case InvalidQrResult():
        _playErrorSound();
        _showSnackBar('Invalid QR code');
        break;
      case NotEnrolledQrResult():
        _playErrorSound();
        _showSnackBar('Student not enrolled in this subject');
        break;
      case AlreadyMarkedQrResult():
        _playErrorSound();
        _showSnackBar('Already marked as ${result.status} at ${_formatTime(result.time)}');
        break;
      case SessionClosedQrResult():
        _playErrorSound();
        _showSnackBar('Session is closed');
        break;
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    _isScanning = false;
  }

  Future<void> _handleValidQr(String studentNumber, String fullName) async {
    final session = _selectedSession!;
    final studentRepo = StudentRepository();
    final attendanceRepo = AttendanceRepository();
    final now = DateTime.now();

    final student = await studentRepo.getByStudentNumber(studentNumber);
    if (student == null) {
      _playErrorSound();
      _showSnackBar('Student not found');
      return;
    }

    final enrollmentRepo = SubjectStudentRepository();
    final isEnrolled = await enrollmentRepo.isEnrolled(session.subjectId, student.id!);
    if (!isEnrolled) {
      _playErrorSound();
      _showSnackBar('$fullName is not enrolled in this subject');
      return;
    }

    final existing = await attendanceRepo.getBySessionAndStudent(session.id!, student.id!);
    if (existing != null) {
      _playErrorSound();
      _showSnackBar('$fullName already marked as ${existing.status}');
      return;
    }

    final status = StatusRules.determineStatus(
      scanTime: now,
      sessionStartTime: session.startTime,
      sessionLateAfterTime: session.lateAfterTime,
      sessionEndTime: session.endTime,
      sessionDate: DateTime.parse(session.date),
    );

    if (status == AttendanceStatus.rejected) {
      _playErrorSound();
      _showSnackBar('Scan time is after session end time');
      return;
    }

    if (status == AttendanceStatus.present) {
      _playPresentSound();
    } else if (status == AttendanceStatus.late) {
      _playLateSound();
    }

    final attendance = Attendance(
      sessionId: session.id!,
      studentId: student.id!,
      status: status.name,
      scannedAt: now.millisecondsSinceEpoch,
      source: 'scan',
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    await attendanceRepo.insert(attendance);

    _showSnackBar('$fullName marked as ${status.name}');
  }

  void _playPresentSound() {
    _audioPlayer.play(AssetSource('sounds/present.wav'));
  }

  void _playLateSound() {
    _audioPlayer.play(AssetSource('sounds/late.wav'));
  }

  void _playErrorSound() {
    _audioPlayer.play(AssetSource('sounds/error.wav'));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: DesignTokens.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: BrandColors.absentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: false, // Don't extend body - we want full screen
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
          style: DesignTokens.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Sessions',
          ),
          const ThemeToggleButton(),
          const SizedBox(width: DesignTokens.space2),
          _buildProfileMenu(isDark),
        ],
      ),
      body: authState is AuthAuthenticated
          ? _buildScanContent(isDark)
          : Center(
              child: Text(
                'Not logged in',
                style: DesignTokens.bodyLarge.copyWith(
                  color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSessions,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        ),
        child: const Icon(Icons.refresh_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // No bottomNavigationBar - full screen scanner
    );
  }

  Widget _buildProfileMenu(bool isDark) {
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

  Widget _buildScanContent(bool isDark) {
    if (_isLoadingSessions) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: BrandColors.primary),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Loading sessions...',
              style: DesignTokens.bodyMedium.copyWith(
                color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
                      color: (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      size: 64,
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space6),
                  Text(
                    'No active sessions',
                    style: DesignTokens.headlineSmall.copyWith(
                      color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Create a session from the Subjects tab or wait for a scheduled session to start',
                    style: DesignTokens.bodyLarge.copyWith(
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space6),
                  PillButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onPressed: _loadSessions,
                    isDark: isDark,
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
                color: isDark ? BrandColors.darkSurface : BrandColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Session',
                    style: DesignTokens.labelLarge.copyWith(
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  DropdownButtonFormField<Session>(
                    initialValue: _selectedSession,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                        borderSide: BorderSide(
                          color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                        borderSide: BorderSide(
                          color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                        borderSide: BorderSide(color: BrandColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? BrandColors.darkBackground : BrandColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space4,
                        vertical: DesignTokens.space3,
                      ),
                    ),
                    dropdownColor: isDark ? BrandColors.darkSurface : BrandColors.lightSurface,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
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
                            style: DesignTokens.bodyMedium,
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
                        style: DesignTokens.bodyLarge.copyWith(
                          color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
                                color: BrandColors.primary,
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
                                    style: DesignTokens.bodyMedium.copyWith(
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
                            color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Camera Permission Required',
                            style: DesignTokens.headlineSmall.copyWith(
                              color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          Text(
                            'Please grant camera permission to scan QR codes',
                            style: DesignTokens.bodyMedium.copyWith(
                              color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          PillButton(
                            label: 'Open Settings',
                            icon: Icons.settings_rounded,
                            onPressed: () => openAppSettings(),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedSession != null) _buildSessionInfoCard(_selectedSession!, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(Session session, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? BrandColors.darkSurface : BrandColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Details',
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Date', session.date, isDark),
              ),
              Expanded(
                child: _buildDetailItem('Time', '${session.startTime} - ${session.endTime}', isDark),
              ),
              Expanded(
                child: _buildDetailItem('Late After', session.lateAfterTime, isDark),
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
                  ? BrandColors.presentGreen.withValues(alpha: 0.12)
                  : (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Text(
              session.status == 'open' ? 'Open' : 'Closed',
              style: DesignTokens.labelSmall.copyWith(
                color: session.status == 'open'
                    ? BrandColors.presentGreen
                    : (isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.space1),
        Text(
          value,
          style: DesignTokens.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}