import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/router/app_router.dart';
import '../../core/services/qr_service.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
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
  late Animation<Offset> _slideAnimation;

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
    _generateQrCode();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _qrAnimationController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredItem(int index, Widget child) {
    return StaggeredItem(key: ValueKey(index), index: index, child: child);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.read(authProvider);
    final student = authState is AuthAuthenticated ? authState.session.student : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? BrandColors.darkSurface : BrandColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusDialog)),
          border: Border.all(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
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
                color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
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
                        style: DesignTokens.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
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
                    style: DesignTokens.bodyMedium.copyWith(
                      color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
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
                          isDark: isDark,
                          padding: const EdgeInsets.all(DesignTokens.space4),
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: BrandColors.primary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: BrandColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      // Student info card
                      SoftCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(DesignTokens.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Information',
                              style: DesignTokens.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space3),
                            _buildInfoRow('Name', student?.fullName ?? 'N/A', context, isDark),
                            _buildInfoRow('Student Number', student?.studentNumber ?? 'N/A', context, isDark),
                            _buildInfoRow('Date', _formatDate(DateTime.now()), context, isDark),
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
                                backgroundColor: BrandColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                                ),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: CircularProgressIndicator(),
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

  Widget _buildInfoRow(String label, String value, BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: DesignTokens.bodyMedium.copyWith(
                color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DesignTokens.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkBackground : BrandColors.lightBackground;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: session?.student != null
            ? _buildProfileMenu(session!, context, textPrimary, textSecondary, isDark)
            : null,
        title: Text(
          session?.student?.fullName ?? 'Home',
          style: DesignTokens.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      body: session != null
          ? _buildHomeContent(session, textPrimary, textSecondary, isDark)
          : Center(
              child: Text(
                'Not logged in',
                style: DesignTokens.bodyLarge.copyWith(color: textSecondary),
              ),
            ),
      bottomNavigationBar: _buildFloatingNavBar(isDark),
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    return FloatingNavBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
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
      ],
      isDark: isDark,
      accentColor: BrandColors.primary,
    );
  }

  Widget _buildHomeContent(UserSession session, Color textPrimary, Color textSecondary, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: () async => _generateQrCode(),
          color: BrandColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space6,
              DesignTokens.space6,
              DesignTokens.space6,
              DesignTokens.space6 + 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick QR access card with staggered entrance
                _buildStaggeredItem(0, SoftTile(
                  isDark: isDark,
                  onTap: _showQrSheet,
                  padding: const EdgeInsets.all(DesignTokens.space5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.space4),
                        decoration: BoxDecoration(
                          color: BrandColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                        ),
                        child: Icon(
                          Icons.qr_code_rounded,
                          size: 32,
                          color: BrandColors.primary,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My QR Code',
                              style: DesignTokens.titleLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space1),
                            Text(
                              'Tap to show your daily attendance code',
                              style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: textSecondary,
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: DesignTokens.space5),

                // Today's sessions
                Text(
                  'Today\'s Sessions',
                  style: DesignTokens.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),

                // TODO: Fetch actual sessions from database
                _buildEmptySessions(context, textPrimary, textSecondary, isDark),

                const SizedBox(height: DesignTokens.space5),

                // Quick stats
                Text(
                  'Quick Stats',
                  style: DesignTokens.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                _buildStatsGrid(context, isDark, textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySessions(BuildContext context, Color textPrimary, Color textSecondary, bool isDark) {
    return SoftCard(
      isDark: isDark,
      padding: const EdgeInsets.all(DesignTokens.space5),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: (isDark ? BrandColors.darkSurfaceVariant : BrandColors.lightSurfaceVariant).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircle),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'No sessions today',
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Your attendance sessions will appear here',
            style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDark, Color textSecondary) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DesignTokens.space3,
      mainAxisSpacing: DesignTokens.space3,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard('Present', '0', BrandColors.presentGreen, context, isDark, textSecondary),
        _buildStatCard('Late', '0', BrandColors.lateAmber, context, isDark, textSecondary),
        _buildStatCard('Absent', '0', BrandColors.absentRed, context, isDark, textSecondary),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, BuildContext context, bool isDark, Color textSecondary) {
    return SoftCard(
      isDark: isDark,
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        children: [
          Text(
            value,
            style: DesignTokens.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            label,
            style: DesignTokens.bodyMedium.copyWith(
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(
    UserSession session,
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final student = session.student!;
    final user = session.user;

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go(AppRoutes.studentProfile);
            break;
          case 'change_avatar':
            _showChangeAvatarDialog(context, isDark, textPrimary, textSecondary);
            break;
          case 'logout':
            _showLogoutDialog(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 0,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: BrandColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    student.fullName.isNotEmpty
                        ? student.fullName[0].toUpperCase()
                        : '?',
                    style: DesignTokens.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BrandColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: DesignTokens.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        student.studentNumber,
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        user.email,
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 20,
                color: textSecondary,
              ),
              const SizedBox(width: DesignTokens.space3),
              Text(
                'My Profile',
                style: DesignTokens.bodyMedium.copyWith(
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_avatar',
          child: Row(
            children: [
              Icon(
                Icons.camera_alt_rounded,
                size: 20,
                color: textSecondary,
              ),
              const SizedBox(width: DesignTokens.space3),
              Text(
                'Change Profile Picture',
                style: DesignTokens.bodyMedium.copyWith(
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 20,
                color: BrandColors.absentRed,
              ),
              const SizedBox(width: DesignTokens.space3),
              Text(
                'Logout',
                style: DesignTokens.bodyMedium.copyWith(
                  color: BrandColors.absentRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space2),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: BrandColors.primary.withValues(alpha: 0.12),
          child: Text(
            student.fullName.isNotEmpty
                ? student.fullName[0].toUpperCase()
                : '?',
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: BrandColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeAvatarDialog(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final student = ref.read(authProvider);
    if (student is! AuthAuthenticated) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? BrandColors.darkSurface : BrandColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(
            color: isDark ? BrandColors.darkOutline : BrandColors.lightOutline,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Profile Picture',
                style: DesignTokens.headlineSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Select a new profile picture',
                style: DesignTokens.bodyMedium.copyWith(color: textSecondary),
              ),
              const SizedBox(height: DesignTokens.space4),
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: BrandColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    student.session.student!.fullName.isNotEmpty
                        ? student.session.student!.fullName[0].toUpperCase()
                        : '?',
                    style: DesignTokens.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BrandColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Choose from Gallery',
                      icon: Icons.photo_library_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Gallery picker coming soon'),
                            backgroundColor: BrandColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                            ),
                          ),
                        );
                      },
                      isDark: isDark,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: PillButton(
                      label: 'Take Photo',
                      icon: Icons.camera_alt_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Camera coming soon'),
                            backgroundColor: BrandColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                            ),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space3),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.pop(context),
                  isDark: isDark,
                  outlined: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final textSecondary = isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusDialog),
          side: BorderSide(color: outlineColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logout',
                style: DesignTokens.headlineSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Are you sure you want to logout?',
                style: DesignTokens.bodyMedium.copyWith(
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.pop(context),
                      isDark: isDark,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: PillButton(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      isDark: isDark,
                      backgroundColor: BrandColors.absentRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}