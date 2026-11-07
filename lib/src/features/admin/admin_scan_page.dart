import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/database/repositories.dart';
import '../../core/router/app_router.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/status_rules.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/auth/auth_provider.dart';

class AdminScanPage extends ConsumerStatefulWidget {
  const AdminScanPage({super.key});

  @override
  ConsumerState<AdminScanPage> createState() => _AdminScanPageState();
}

class _AdminScanPageState extends ConsumerState<AdminScanPage> {
  int _selectedIndex = 2;
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  Session? _selectedSession;
  List<Session> _availableSessions = [];
  bool _isLoadingSessions = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _soundTimer;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _loadSessions();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _soundTimer?.cancel();
    super.dispose();
  }

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
        // Scan - already here
        break;
      case 3:
        context.go(AppRoutes.adminRecords);
        break;
      case 4:
        context.go(AppRoutes.adminSettings);
        break;
    }
  }

  Future<void> _loadSessions() async {
    final sessionRepo = SessionRepository();
    final now = DateTime.now();
    final todayStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Get open sessions for today
    final todaySessions = await sessionRepo.getSessionsForDate(todayStr);
    final openSessions = todaySessions.where((s) => s.status == 'open').toList();

    // Also get all open sessions
    final allOpenSessions = await sessionRepo.getOpenSessions();

    // Combine and deduplicate
    final allSessions = <Session>[];
    final seenIds = <int>{};

    for (final s in [...openSessions, ...allOpenSessions]) {
      if (s.id != null && !seenIds.contains(s.id)) {
        seenIds.add(s.id!);
        allSessions.add(s);
      }
    }

    // Sort by start time
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

    // Small delay to prevent rapid re-scanning
    await Future.delayed(const Duration(milliseconds: 1500));
    _isScanning = false;
  }

  Future<void> _handleValidQr(String studentNumber, String fullName) async {
    final session = _selectedSession!;
    final studentRepo = StudentRepository();
    final attendanceRepo = AttendanceRepository();
    final now = DateTime.now();

    // Find student by student number
    final student = await studentRepo.getByStudentNumber(studentNumber);
    if (student == null) {
      _playErrorSound();
      _showSnackBar('Student not found');
      return;
    }

    // Check if student is enrolled in this subject
    final enrollmentRepo = SubjectStudentRepository();
    final isEnrolled = await enrollmentRepo.isEnrolled(session.subjectId, student.id!);
    if (!isEnrolled) {
      _playErrorSound();
      _showSnackBar('$fullName is not enrolled in this subject');
      return;
    }

    // Check if already marked
    final existing = await attendanceRepo.getBySessionAndStudent(session.id!, student.id!);
    if (existing != null) {
      _playErrorSound();
      _showSnackBar('$fullName already marked as ${existing.status}');
      return;
    }

    // Determine status based on scan time
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

    // Play sound based on status
    if (status == AttendanceStatus.present) {
      _playPresentSound();
    } else if (status == AttendanceStatus.late) {
      _playLateSound();
    }

    // Save attendance
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
        content: Text(message),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance'),
        actions: [
          IconButton(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Sessions',
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: authState is AuthAuthenticated
          ? _buildScanContent()
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

  Widget _buildScanContent() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'No active sessions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create a session from the Subjects tab or wait for a scheduled session to start',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadSessions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Session selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Session>(
                value: _selectedSession,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onSessionChanged,
              ),
            ],
          ),
        ),

        // Scanner preview
        Expanded(
          child: _selectedSession == null
              ? Center(
                  child: Text(
                    'Select a session to start scanning',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),
                    // Overlay with scan area indicator
                    Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: BrandColors.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // Status indicator
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
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
                    // Torch button
                    Positioned(
                      bottom: 160,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: () => _scannerController?.toggleTorch(),
                        child: const Icon(Icons.flash_on_rounded),
                      ),
                    ),
                  ],
                ),
        ),

        // Session info card
        if (_selectedSession != null) _buildSessionInfoCard(_selectedSession!),
      ],
    );
  }

  Widget _buildSessionInfoCard(Session session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
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
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Date', session.date),
              ),
              Expanded(
                child: _buildDetailItem('Time', '${session.startTime} - ${session.endTime}'),
              ),
              Expanded(
                child: _buildDetailItem('Late After', session.lateAfterTime),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(
                  session.status == 'open' ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    color: session.status == 'open'
                        ? BrandColors.presentGreen
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                backgroundColor: session.status == 'open'
                    ? BrandColors.presentGreen.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}