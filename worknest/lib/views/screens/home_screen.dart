import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../models/attendance_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'ot_request_screen.dart';
import 'payslip_screen.dart';
import '../../viewmodels/payslip_viewmodel.dart';
import 'chat_screen.dart';
import '../widgets/home/info_item.dart';
import '../widgets/home/clock_time_box.dart';
import '../widgets/home/status_badge.dart';
import '../widgets/home/quick_action_card.dart';
import '../widgets/home/mini_stat.dart';
import '../widgets/home/recent_attendance_row.dart';
import '../widgets/home/profile_row.dart';
import '../widgets/home/work_type_button.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;
  final Function(int)? onNavigateToTab;
  final int unreadNotifCount;
  final VoidCallback? onNotifTap;

  const HomeScreen({
    super.key,
    required this.user,
    required this.company,
    this.onNavigateToTab,
    this.unreadNotifCount = 0,
    this.onNotifTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeViewModel _viewModel;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(user: widget.user, company: widget.company);
    _viewModel.addListener(_onViewModelChanged);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_viewModel.successMessage != null) {
      _showSnackbar(_viewModel.successMessage!, isError: false);
      _viewModel.clearMessages();
    } else if (_viewModel.errorMessage != null) {
      _showSnackbar(_viewModel.errorMessage!, isError: true);
      _viewModel.clearMessages();
    }
    setState(() {});
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showClockInOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clock In',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            const Text('Where are you working from today?',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            WorkTypeButton(
              icon: Icons.business_rounded,
              label: 'In Office',
              subtitle: widget.company.locationEnabled
                  ? 'GPS will verify your location'
                  : 'No location check required',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(context);
                _viewModel.clockIn('office');
              },
            ),
            const SizedBox(height: 12),
            WorkTypeButton(
              icon: Icons.home_rounded,
              label: 'Work From Home',
              subtitle: 'No location check required',
              color: AppTheme.success,
              onTap: () {
                Navigator.pop(context);
                _viewModel.clockIn('wfh');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: HapticRefreshIndicator(
          onRefresh: _viewModel.loadTodayAttendance,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAttendanceCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildRecentAttendance(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner
        Container(
          height: 130,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                    Text(
                      widget.user.fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    if (widget.user.position != null)
                      Text(
                        widget.user.position!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                  ],
                ),
                // Bell + profile icons
                Row(
                  children: [
                    // Bell icon with badge
                    GestureDetector(
                      onTap: widget.onNotifTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          if (widget.unreadNotifCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  widget.unreadNotifCount > 9
                                      ? '9+'
                                      : '${widget.unreadNotifCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Profile avatar
                    GestureDetector(
                      onTap: _showProfileSheet,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          widget.user.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // White info card below the banner
        Padding(
          padding: const EdgeInsets.only(top: 110),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeInfoItem(
                      icon: Icons.badge_rounded,
                      label: 'Employee ID',
                      value: widget.user.employeeId,
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: HomeInfoItem(
                      icon: Icons.domain_rounded,
                      label: 'Department',
                      value: widget.user.department ?? widget.company.name,
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: HomeInfoItem(
                      icon: Icons.today_rounded,
                      label: 'Today',
                      value: DateFormat('d MMM').format(_now),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFE5E7EB),
      );

  // ── Attendance Card ───────────────────────────────────────────────────────

  Widget _buildAttendanceCard() {
    final attendance = _viewModel.todayAttendance;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fingerprint_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text("Today's Attendance",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                  ],
                ),
                // Live clock
                Text(
                  '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: -0.5),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Clock in/out times
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: ClockTimeBox(
                    label: 'Clock In',
                    time: attendance?.clockIn != null
                        ? DateFormat('hh:mm a').format(attendance!.clockIn!)
                        : '--:--',
                    icon: Icons.login_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClockTimeBox(
                    label: 'Clock Out',
                    time: attendance?.clockOut != null
                        ? DateFormat('hh:mm a').format(attendance!.clockOut!)
                        : '--:--',
                    icon: Icons.logout_rounded,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClockTimeBox(
                    label: 'Duration',
                    time: attendance?.durationText ?? '--:--',
                    icon: Icons.timer_rounded,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Status badge row
          if (attendance != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  StatusBadge(
                    label: attendance.status == 'late' ? 'Late' : 'Present',
                    color: attendance.status == 'late'
                        ? AppTheme.warning
                        : AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: attendance.type == 'wfh'
                        ? 'Work From Home'
                        : 'In Office',
                    color: attendance.type == 'wfh'
                        ? const Color(0xFF06B6D4)
                        : AppTheme.primary,
                  ),
                ],
              ),
            ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _viewModel.isLoading
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                    ),
                  )
                : !_viewModel.isClockedIn
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showClockInOptions,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Clock In Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    : _viewModel.isClockedIn && !_viewModel.isClockedOut
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _viewModel.clockOut,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Clock Out Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppTheme.success.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppTheme.success, size: 18),
                                SizedBox(width: 8),
                                Text('Attendance Complete',
                                    style: TextStyle(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            QuickActionCard(
              icon: Icons.calendar_month_rounded,
              label: 'My\nAttendance',
              color: AppTheme.primary,
              onTap: () => widget.onNavigateToTab?.call(1),
            ),
            QuickActionCard(
              icon: Icons.beach_access_rounded,
              label: 'My\nLeave',
              color: const Color(0xFF06B6D4),
              onTap: () => widget.onNavigateToTab?.call(2),
            ),
            QuickActionCard(
              icon: Icons.receipt_long_rounded,
              label: 'My\nClaims',
              color: AppTheme.secondary,
              onTap: () => widget.onNavigateToTab?.call(3),
            ),
            QuickActionCard(
              icon: Icons.access_time_rounded,
              label: 'OT\nRequest',
              color: AppTheme.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtRequestScreen(
                    user: widget.user,
                    company: widget.company,
                  ),
                ),
              ),
            ),
            QuickActionCard(
              icon: Icons.receipt_long_rounded,
              label: 'My\nPayslip',
              color: const Color(0xFF0EA5E9),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PayslipScreen(
                    viewModel: PayslipViewModel(userId: widget.user.id),
                  ),
                ),
              ),
            ),
            QuickActionCard(
              icon: Icons.campaign_rounded,
              label: 'Announce\nments',
              color: AppTheme.warning,
              onTap: () => _showComingSoon('Announcements'),
            ),
            // In your quick actions grid, add:
          QuickActionCard(
            icon: Icons.smart_toy_rounded,
            label: 'HR Assistant',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — coming soon!'),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Recent Attendance ─────────────────────────────────────────────────────

  Widget _buildRecentAttendance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Attendance',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            GestureDetector(
              onTap: () => widget.onNavigateToTab?.call(1),
              child: const Text('See all',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Month stat strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: MiniStat(
                  label: 'Total',
                  value: '${_viewModel.monthTotal}',
                  color: AppTheme.primary,
                ),
              ),
              Container(width: 1, height: 28, color: AppTheme.primary.withValues(alpha: 0.15)),
              Expanded(
                child: MiniStat(
                  label: 'Present',
                  value: '${_viewModel.monthPresent}',
                  color: AppTheme.success,
                ),
              ),
              Container(width: 1, height: 28, color: AppTheme.primary.withValues(alpha: 0.15)),
              Expanded(
                child: MiniStat(
                  label: 'Late',
                  value: '${_viewModel.monthLate}',
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_viewModel.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
        else if (_viewModel.recentAttendance.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.textMuted, size: 18),
                SizedBox(width: 10),
                Text('No recent records.',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          )
        else
          ...(_viewModel.recentAttendance
              .map((r) => RecentAttendanceRow(record: r))),
      ],
    );
  }

  // ── Sign Out Confirmation ─────────────────────────────────────────────────

  Future<void> _confirmSignOut(BuildContext sheetContext) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.of(sheetContext).pop(); // close the profile sheet
    if (!mounted) return;

    final nav = Navigator.of(context);

    // Non-dismissible loading overlay while sign-out completes
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: SizedBox(
            width: 88,
            height: 88,
            child: Card(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    await AuthService().signOut();

    unawaited(nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    ));
  }

  // ── Profile Bottom Sheet ──────────────────────────────────────────────────

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primary,
              child: Text(widget.user.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22)),
            ),
            const SizedBox(height: 12),
            Text(widget.user.fullName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            if (widget.user.position != null)
              Text(widget.user.position!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            ProfileRow(
                icon: Icons.badge_rounded,
                label: 'Employee ID',
                value: widget.user.employeeId),
            if (widget.user.department != null)
              ProfileRow(
                  icon: Icons.domain_rounded,
                  label: 'Department',
                  value: widget.user.department!),
            ProfileRow(
                icon: Icons.business_rounded,
                label: 'Company',
                value: widget.company.name),
            ProfileRow(
                icon: Icons.email_rounded,
                label: 'Email',
                value: widget.user.email ?? '—',
                note: 'Contact HR to change'),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppTheme.danger),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w600)),
              onTap: () => _confirmSignOut(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

