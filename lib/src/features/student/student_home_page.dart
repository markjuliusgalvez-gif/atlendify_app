import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/router/app_router.dart';
import '../../core/services/qr_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/auth/auth_provider.dart';

class StudentHomePage extends ConsumerStatefulWidget {
  const StudentHomePage({super.key});

  @override
  ConsumerState<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends ConsumerState<StudentHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _qrData;
  late AnimationController _qrAnimationController;
  late Animation<double> _qrScaleAnimation;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  static const List<NavigationDestination> _destinations = [
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
  ];

  @override
  void initState() {
    super.initState();
    _qrAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _qrScaleAnimation = CurvedAnimation(
      parent: _qrAnimationController,
      curve: Curves.elasticOut,
    );
    _entranceController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: DesignTokens.emphasizedCurve),
    );
    _generateQrCode();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _qrAnimationController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _generateQrCode() {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      final session = authState.session;
      if (session.student != null) {
        final qr = QrService.generateQrData(
          studentNumber: session.student!.studentNumber,
          fullName: session.student!.fullName,
          date: DateTime.now(),
        );
        setState(() {
          _qrData = qr;
        });
        _qrAnimationController.forward(from: 0);
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        context.go(AppRoutes.studentRecords);
        break;
      case 2:
        context.go(AppRoutes.studentProfile);
        break;
    }
  }

  void _showQrSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQrSheet(context),
    );
  }

  Widget _buildQrSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.read(authProvider);
    final student = authState is AuthAuthenticated ? authState.session.student : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusDialog)),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s QR Code',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    'Scan this code to mark your attendance',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // QR Code
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space5, vertical: DesignTokens.space3),
                child: Column(
                  children: [
                    if (_qrData != null) ...[
                      ScaleTransition(
                        scale: _qrScaleAnimation,
                        child: SoftCard(
                          isDark: Theme.of(context).brightness == Brightness.dark,
                          padding: const EdgeInsets.all(DesignTokens.space4),
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: colorScheme.primary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      // Student info card
                      SoftCard(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        padding: const EdgeInsets.all(DesignTokens.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Information',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space3),
                            _buildInfoRow('Name', student?.fullName ?? 'N/A', colorScheme, textTheme),
                            _buildInfoRow('Student Number', student?.studentNumber ?? 'N/A', colorScheme, textTheme),
                            _buildInfoRow('Date', _formatDate(DateTime.now()), colorScheme, textTheme),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space3),
                      // Refresh button
                      SizedBox(
                        width: double.infinity,
                        child: PillButton(
                          label: 'Refresh QR Code',
                          icon: Icons.refresh_rounded,
                          onPressed: () {
                            _generateQrCode();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('QR code refreshed'),
                                backgroundColor: colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                                ),
                              ),
                            );
                          },
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: CircularProgressIndicator(color: colorScheme.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final session = authState is AuthAuthenticated ? authState.session : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: true,
        child: session != null
            ? _buildHomeContent(session, colorScheme, textTheme)
            : Center(
                child: Text(
                  'Not logged in',
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: _destinations,
        accentColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildHomeContent(UserSession session, ColorScheme colorScheme, TextTheme textTheme) {
    final student = session.student!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async => _generateQrCode(),
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            DesignTokens.space6,
            DesignTokens.space6,
            DesignTokens.space6,
            DesignTokens.space6 + DesignTokens.bottomBarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppHeader with profile menu
              AppHeader(
                title: 'Good ${_getTimeOfDay()}, ${student.fullName}',
                subtitle: 'Ready to mark your attendance?',
                showProfileMenu: true,
              ),
              const SizedBox(height: DesignTokens.space5),

              // Quick QR access card
              _buildQrCodeCard(colorScheme, textTheme),
              const SizedBox(height: DesignTokens.space5),

              // Today's sessions
              Text(
                'Attendance',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),

              _buildEmptySessions(colorScheme, textTheme),

              const SizedBox(height: DesignTokens.space5),

              // Quick stats - use Row with Expanded instead of GridView
              Text(
                'My Statistics',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              _buildStatsRow(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildEmptySessions(ColorScheme colorScheme, TextTheme textTheme) {
    return SoftCard(
      isDark: Theme.of(context).brightness == Brightness.dark,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'No sessions today',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Your attendance sessions will appear here',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Present', '0', const Color(0xFF1B8A3A), colorScheme, textTheme, Icons.check_circle_rounded)),
        SizedBox(width: DesignTokens.space3),
        Expanded(child: _buildStatCard('Late', '0', const Color(0xFFF5A623), colorScheme, textTheme, Icons.access_time_rounded)),
        SizedBox(width: DesignTokens.space3),
        Expanded(child: _buildStatCard('Absent', '0', const Color(0xFFD0021B), colorScheme, textTheme, Icons.cancel_rounded)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, ColorScheme colorScheme, TextTheme textTheme, IconData icon) {
    return SoftCard(
      isDark: Theme.of(context).brightness == Brightness.dark,
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// QR Code card widget for quick access
  Widget _buildQrCodeCard(ColorScheme colorScheme, TextTheme textTheme) {
    return SoftTile(
      isDark: Theme.of(context).brightness == Brightness.dark,
      onTap: _showQrSheet,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
            child: const Icon(
              Icons.qr_code_rounded,
              size: 32,
              color: Color(0xFF1976D2), // Explicit blue for QR
            ),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My QR Code',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Tap to show your daily attendance code',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF70757A), // Neutral gray
          ),
        ],
      ),
    );
  }

  }