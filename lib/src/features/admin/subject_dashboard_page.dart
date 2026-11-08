import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/database/repositories.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class SubjectDashboardPage extends ConsumerStatefulWidget {
  final int subjectId;

  const SubjectDashboardPage({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDashboardPage> createState() => _SubjectDashboardPageState();
}

class _SubjectDashboardPageState extends ConsumerState<SubjectDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Subject? _subject;
  List<Student> _enrolledStudents = [];
  Session? _activeSession;
  bool _isLoading = true;
  String? _errorMessage;

  // QR Scanner state
  MobileScannerController? _scannerController;
  bool _cameraPermissionGranted = false;
  bool _showScanner = false;
  String? _lastScanResult;

  // Attendance data
  List<Attendance> _attendanceRecords = [];
  bool _isLoadingAttendance = false;

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

    _loadData();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _cameraPermissionGranted = status.isGranted;
      });
      if (_cameraPermissionGranted) {
        _initializeScanner();
      }
    }
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  Future<void> _loadData() async {
    try {
      final subjectRepo = SubjectRepository();
      final enrollmentRepo = SubjectStudentRepository();
      final sessionRepo = SessionRepository();

      final subject = await subjectRepo.getById(widget.subjectId);
      final enrolledStudents = await enrollmentRepo.getEnrolledStudents(widget.subjectId);
      final sessions = await sessionRepo.getBySubject(widget.subjectId);

      // Find active session (open status)
      Session? activeSession;
      for (final session in sessions) {
        if (session.status == 'open') {
          activeSession = session;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _subject = subject;
          _enrolledStudents = enrolledStudents;
          _activeSession = activeSession;
          _isLoading = false;
        });
        // Load attendance records if there's an active session
        if (activeSession != null) {
          _loadAttendanceRecords(activeSession.id!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceRecords(int sessionId) async {
    setState(() => _isLoadingAttendance = true);
    try {
      final attendanceRepo = AttendanceRepository();
      final records = await attendanceRepo.getBySession(sessionId);
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

  Future<void> _loadEnrolledStudents() async {
    try {
      final enrollmentRepo = SubjectStudentRepository();
      final enrolledStudents = await enrollmentRepo.getEnrolledStudents(widget.subjectId);
      if (mounted) {
        setState(() {
          _enrolledStudents = enrolledStudents;
        });
      }
    } catch (e) {
      // Silently handle error - enrollment list update is secondary
      debugPrint('Error loading enrolled students: $e');
    }
  }

  void _toggleScanner() {
    setState(() {
      _showScanner = !_showScanner;
      if (_showScanner && _scannerController != null) {
        _scannerController!.start();
      } else {
        _scannerController?.stop();
      }
    });
  }

  void _onQrDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScanResult) return;

    _lastScanResult = code;
    _handleQrScan(code);
  }

  Future<void> _handleQrScan(String qrData) async {
    // Parse QR data (format: studentNumber|fullName|timestamp)
    final parts = qrData.split('|');
    if (parts.length < 2) {
      _showSnackBar('Invalid QR code format', isError: true);
      return;
    }

    final studentNumber = parts[0];
    final fullName = parts[1];

    if (_activeSession == null) {
      _showSnackBar('No active session. Start a session first.', isError: true);
      return;
    }

    final studentRepo = StudentRepository();
    final enrollmentRepo = SubjectStudentRepository();
    final attendanceRepo = AttendanceRepository();

    // Check if student already exists in database
    Student? student = await studentRepo.getByStudentNumber(studentNumber);

    // If student doesn't exist, create new student record
    if (student == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final newStudent = Student(
        id: null,
        studentNumber: studentNumber,
        fullName: fullName,
        createdAt: now,
        updatedAt: now,
      );
      final newStudentId = await studentRepo.insert(newStudent);
      student = await studentRepo.getById(newStudentId);
      _showSnackBar('New student registered: $fullName', isError: false);
    }

    // At this point student is guaranteed to be non-null
    final studentId = student!.id!;

    // Auto-enroll student in this subject if not already enrolled
    final isEnrolled = await enrollmentRepo.isEnrolled(widget.subjectId, studentId);
    if (!isEnrolled) {
      await enrollmentRepo.enroll(widget.subjectId, studentId);
      _showSnackBar('$fullName enrolled in ${_subject?.name ?? 'subject'}', isError: false);
    }

    // Check if already marked for this session
    final existingAttendance = await attendanceRepo.getBySessionAndStudent(_activeSession!.id!, studentId);
    if (existingAttendance != null) {
      _showSnackBar('$fullName already marked as ${existingAttendance.status}', isError: true);
      return;
    }

    // Determine status based on time
    final now = DateTime.now();
    final lateAfterTime = _parseTime(_activeSession!.lateAfterTime);
    final startTime = _parseTime(_activeSession!.startTime);

    String status = 'present';
    if (now.isAfter(lateAfterTime)) {
      status = 'late';
    } else if (now.isBefore(startTime)) {
      status = 'present'; // Early is still present
    }

    // Mark attendance
    try {
      await attendanceRepo.insert(Attendance(
        sessionId: _activeSession!.id!,
        studentId: studentId,
        status: status,
        scannedAt: now.millisecondsSinceEpoch,
        source: 'scan',
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ));

      if (mounted) {
        // Immediately update local state for instant UI refresh
        setState(() {
          // Reload attendance records
          _loadAttendanceRecords(_activeSession!.id!);
          // Reload enrolled students to include newly enrolled student
          _loadEnrolledStudents();
        });
        _showSnackBar('Attendance marked: $fullName - $status', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error marking attendance: $e', isError: true);
    }
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? BrandColors.absentRed : BrandColors.presentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        ),
      ),
    );
  }

  Future<void> _showStartSessionDialog() async {
    final sessionRepo = SessionRepository();
    final today = DateTime.now();
    final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    // Check if session already exists for today
    final existing = await sessionRepo.getBySubjectAndDate(widget.subjectId, dateStr);
    if (existing != null) {
      if (existing.status == 'open') {
        _showSnackBar('Session already open for today', isError: true);
      } else {
        // Reopen closed session
        await sessionRepo.update(Session(
          id: existing.id,
          subjectId: existing.subjectId,
          date: existing.date,
          startTime: existing.startTime,
          lateAfterTime: existing.lateAfterTime,
          endTime: existing.endTime,
          status: 'open',
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));
        _loadData();
        _showSnackBar('Session reopened', isError: false);
      }
      return;
    }

    // Create new session using subject times
    if (_subject != null) {
      await sessionRepo.insert(Session(
        subjectId: widget.subjectId,
        date: dateStr,
        startTime: _subject!.startTime,
        lateAfterTime: _subject!.lateAfterTime,
        endTime: _subject!.endTime,
        status: 'open',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _loadData();
      _showSnackBar('New session started', isError: false);
    }
  }

  Future<void> _closeSession() async {
    if (_activeSession == null) return;

    final sessionRepo = SessionRepository();
    final attendanceRepo = AttendanceRepository();

    try {
      // Finalize absentees
      final enrolledIds = _enrolledStudents.map((s) => s.id!).toList();
      await attendanceRepo.finalizeAbsentees(_activeSession!.id!, enrolledIds, DateTime.now().millisecondsSinceEpoch);

      // Close session
      await sessionRepo.finalize(_activeSession!.id!, DateTime.now().millisecondsSinceEpoch);

      _loadData();
      _showSnackBar('Session closed and finalized', isError: false);
    } catch (e) {
      _showSnackBar('Error closing session: $e', isError: true);
    }
  }

  Future<void> _exportToPdf() async {
    if (_subject == null) return;

    final pdf = pw.Document();

    // Get attendance counts
    final attendanceRepo = AttendanceRepository();
    final counts = _activeSession != null
        ? await attendanceRepo.getCountsBySession(_activeSession!.id!)
        : {'present': 0, 'late': 0, 'absent': 0};

    // Get admin name from auth state
    final authState = ref.read(authProvider);
    String adminName = 'Admin';
    if (authState is AuthAuthenticated) {
      final student = authState.session.student;
      if (student != null && student.fullName.isNotEmpty) {
        adminName = student.fullName;
      }
    }

    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _subject!.name,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_subject!.code} - Section ${_subject!.section}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                    pw.Text('Report by: $adminName', style: pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard('Total Enrolled', _enrolledStudents.length.toString(), PdfColors.blue),
              _buildSummaryCard('Present', (counts['present'] ?? 0).toString(), PdfColors.green),
              _buildSummaryCard('Late', (counts['late'] ?? 0).toString(), PdfColors.amber),
              _buildSummaryCard('Absent', (counts['absent'] ?? 0).toString(), PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 20),

          // Session Details (if active)
          if (_activeSession != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Active Session', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('${_activeSession!.date} | ${_activeSession!.startTime} - ${_activeSession!.endTime}',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('OPEN', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Attendance Table
          pw.Text('Attendance Records', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildAttendanceTable(),
        ],
      ),
    );

    // Share/save PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_subject!.code}_${_subject!.section}_Attendance_$dateStr.pdf',
    );
  }

  pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildAttendanceTable() {
    // Combine enrolled students with attendance records
    final attendanceMap = {for (var a in _attendanceRecords) a.studentId: a};

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),   // Student ID
        1: const pw.FlexColumnWidth(3),     // Name
        2: const pw.FlexColumnWidth(2),     // Section
        3: const pw.FlexColumnWidth(2),     // Status
        4: const pw.FlexColumnWidth(2.5),   // Timestamp
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildTableHeader('Student ID'),
            _buildTableHeader('Student Name'),
            _buildTableHeader('Section'),
            _buildTableHeader('Status'),
            _buildTableHeader('Scan Time'),
          ],
        ),
        // Data rows
        ..._enrolledStudents.map((student) {
          final attendance = attendanceMap[student.id];
          final status = attendance?.status ?? 'Not Marked';
          final scannedAt = attendance?.scannedAt;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: _enrolledStudents.indexOf(student).isEven ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              _buildTableCell(student.studentNumber),
              _buildTableCell(student.fullName),
              _buildTableCell(_subject?.section ?? ''),
              _buildStatusCell(status),
              _buildTableCell(
                scannedAt != null
                    ? _formatTimestamp(scannedAt)
                    : '-',
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _buildStatusCell(String status) {
    PdfColor color;
    switch (status) {
      case 'present':
        color = PdfColors.green;
        break;
      case 'late':
        color = PdfColors.amber;
        break;
      case 'absent':
        color = PdfColors.red;
        break;
      default:
        color = PdfColors.grey600;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          status.toUpperCase(),
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
        ),
        title: Text(
          _subject?.name ?? 'Subject Dashboard',
          style: DesignTokens.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_activeSession != null && _enrolledStudents.isNotEmpty)
            IconButton(
              onPressed: _exportToPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 24),
              tooltip: 'Export Attendance to PDF',
              color: textPrimary,
            ),
          const ThemeToggleButton(),
          const SizedBox(width: DesignTokens.space2),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? _buildLoadingState(isDark, textPrimary, textSecondary)
              : _errorMessage != null
                  ? _buildErrorState(isDark, textPrimary, textSecondary)
                  : _buildDashboardContent(isDark, textPrimary, textSecondary),

          // QR Scanner overlay
          if (_showScanner && _cameraPermissionGranted && _scannerController != null)
            _buildScannerOverlay(isDark, textPrimary),
        ],
      ),
      floatingActionButton: _showScanner ? null : _buildFab(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // No bottomNavigationBar - this is a detail page
    );
  }

  Widget _buildLoadingState(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: BrandColors.primary),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Loading subject dashboard...',
            style: DesignTokens.bodyMedium.copyWith(
              color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color textPrimary, Color textSecondary) {
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
              'Failed to load dashboard',
              style: DesignTokens.headlineSmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              _errorMessage!,
              style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space4),
            PillButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: _loadData,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(bool isDark, Color textPrimary, Color textSecondary) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: BrandColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space6,
                    DesignTokens.space6,
                    DesignTokens.space6,
                    DesignTokens.space4,
                  ),
                  child: _buildHeader(isDark, textPrimary, textSecondary),
                ),
              ),

              // Session status & controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space6,
                    0,
                    DesignTokens.space6,
                    DesignTokens.space4,
                  ),
                  child: _buildSessionCard(isDark, textPrimary, textSecondary),
                ),
              ),

              // Attendance Table
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space6,
                  0,
                  DesignTokens.space6,
                  DesignTokens.space6 + 120,
                ),
                sliver: _isLoadingAttendance
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(color: BrandColors.primary),
                        ),
                      )
                    : _enrolledStudents.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyStudents(isDark, textPrimary, textSecondary),
                          )
                        : SliverList.separated(
                            itemCount: _enrolledStudents.length,
                            separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space3),
                            itemBuilder: (context, index) {
                              final student = _enrolledStudents[index];
                              return _buildStudentTile(student, isDark, textPrimary, textSecondary, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _subject?.name ?? 'Subject Dashboard',
                style: DesignTokens.headlineMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.space1),
              Text(
                '${_subject?.code ?? ''} - Section ${_subject?.section ?? ''}',
                style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        // Enrollment count badge
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space1,
            ),
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Text(
              '${_enrolledStudents.length} students',
              style: DesignTokens.labelMedium.copyWith(
                color: BrandColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(bool isDark, Color textPrimary, Color textSecondary) {
    final hasActiveSession = _activeSession != null;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      isDark: isDarkTheme,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: hasActiveSession
                      ? BrandColors.presentGreen.withValues(alpha: 0.12)
                      : BrandColors.lateAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                ),
                child: Icon(
                  hasActiveSession ? Icons.event_available_rounded : Icons.event_busy_rounded,
                  color: hasActiveSession ? BrandColors.presentGreen : BrandColors.lateAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActiveSession ? 'Active Session' : 'No Active Session',
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      hasActiveSession
                          ? 'Session is open. Scan QR codes to mark attendance.'
                          : 'Start a session to begin taking attendance.',
                      style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          Row(
            children: [
              if (!hasActiveSession) ...[
                Expanded(
                  child: PillButton(
                    label: 'Start Session',
                    icon: Icons.play_circle_outline_rounded,
                    onPressed: _showStartSessionDialog,
                    isDark: isDarkTheme,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: PillButton(
                    label: 'Close Session',
                    icon: Icons.stop_circle_outlined,
                    onPressed: _closeSession,
                    isDark: isDarkTheme,
                    outlined: true,
                  ),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: PillButton(
                    label: _showScanner ? 'Stop Scanner' : 'Start Scanner',
                    icon: _showScanner ? Icons.videocam_off_rounded : Icons.qr_code_scanner_rounded,
                    onPressed: _toggleScanner,
                    isDark: isDarkTheme,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStudents(bool isDark, Color textPrimary, Color textSecondary) {
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
                Icons.people_outline_rounded,
                size: 64,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'No students enrolled',
              style: DesignTokens.headlineSmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              'Add students to this subject from the Subjects page',
              style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(Student student, bool isDark, Color textPrimary, Color textSecondary, int index) {
    // Find attendance for this student in the active session
    Attendance? studentAttendance;
    if (_activeSession != null) {
      try {
        studentAttendance = _attendanceRecords.firstWhere(
          (a) => a.studentId == student.id && a.sessionId == _activeSession!.id,
        );
      } catch (e) {
        studentAttendance = null;
      }
    }

    Color? statusColor;
    String statusText = 'Not Marked';
    if (studentAttendance != null) {
      switch (studentAttendance.status) {
        case 'present':
          statusColor = BrandColors.presentGreen;
          statusText = 'Present';
          break;
        case 'late':
          statusColor = BrandColors.lateAmber;
          statusText = 'Late';
          break;
        case 'absent':
          statusColor = BrandColors.absentRed;
          statusText = 'Absent';
          break;
        default:
          statusColor = textSecondary;
          statusText = studentAttendance.status;
      }
    }

    String formattedTime = '';
    if (studentAttendance != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(studentAttendance.scannedAt);
      formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
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
      child: SoftTile(
        isDark: isDark,
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: BrandColors.primary.withValues(alpha: 0.12),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                style: DesignTokens.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BrandColors.primary,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space4),
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
                  const SizedBox(height: DesignTokens.space1),
                  Row(
                    children: [
                      Text(
                        student.studentNumber,
                        style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                      ),
                      const SizedBox(width: DesignTokens.space3),
                      Text(
                        _subject?.section ?? '',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Attendance status badge with time
            if (_activeSession != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: studentAttendance != null
                      ? statusColor!.withValues(alpha: 0.12)
                      : (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: studentAttendance == null
                      ? Border.all(
                          color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (studentAttendance != null)
                      Icon(
                        studentAttendance.status == 'present'
                            ? Icons.check_circle_rounded
                            : studentAttendance.status == 'late'
                                ? Icons.access_time_rounded
                                : Icons.cancel_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                    if (studentAttendance != null) const SizedBox(width: DesignTokens.space1),
                    Text(
                      statusText,
                      style: DesignTokens.labelSmall.copyWith(
                        color: studentAttendance != null
                            ? statusColor
                            : textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (formattedTime.isNotEmpty) ...[
                      const SizedBox(width: DesignTokens.space2),
                      Text(
                        formattedTime,
                        style: DesignTokens.labelSmall.copyWith(
                          color: textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(bool isDark) {
    return FloatingActionButton(
      onPressed: _toggleScanner,
      backgroundColor: BrandColors.primary,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      child: Icon(
        _showScanner ? Icons.videocam_off_rounded : Icons.qr_code_scanner_rounded,
        size: 28,
      ),
    );
  }

  Widget _buildScannerOverlay(bool isDark, Color textPrimary) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleScanner,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Expanded(
                    child: Text(
                      'QR Scanner - ${_subject?.name ?? 'Subject'}',
                      style: DesignTokens.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_activeSession != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space3,
                        vertical: DesignTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.presentGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                      ),
                      child: Text(
                        'ACTIVE SESSION',
                        style: DesignTokens.labelSmall.copyWith(
                          color: BrandColors.presentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Scanner view
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                  child: MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onQrDetected,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Bottom instructions
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space6),
              child: Column(
                children: [
                  if (_lastScanResult != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DesignTokens.space4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Scan:',
                            style: DesignTokens.labelMedium.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: DesignTokens.space1),
                          Text(
                            _lastScanResult!,
                            style: DesignTokens.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Point camera at student QR code to mark attendance',
                    style: DesignTokens.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}