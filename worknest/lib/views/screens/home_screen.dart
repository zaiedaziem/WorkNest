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

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;
  final Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.user,
    required this.company,
    this.onNavigateToTab,
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
            _WorkTypeButton(
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
            _WorkTypeButton(
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
        child: RefreshIndicator(
          color: AppTheme.primary,
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
                // Settings / profile icon
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
                    child: _InfoItem(
                      icon: Icons.badge_rounded,
                      label: 'Employee ID',
                      value: widget.user.employeeId,
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.domain_rounded,
                      label: 'Department',
                      value: widget.user.department ?? widget.company.name,
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _InfoItem(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _ClockTimeBox(
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
                  child: _ClockTimeBox(
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
                  child: _ClockTimeBox(
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
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              child: Row(
                children: [
                  _StatusBadge(
                    label: attendance.status == 'late' ? 'Late' : 'Present',
                    color: attendance.status == 'late'
                        ? AppTheme.warning
                        : AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
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
            _QuickActionCard(
              icon: Icons.calendar_month_rounded,
              label: 'My\nAttendance',
              color: AppTheme.primary,
              onTap: () => widget.onNavigateToTab?.call(1),
            ),
            _QuickActionCard(
              icon: Icons.beach_access_rounded,
              label: 'My\nLeave',
              color: const Color(0xFF06B6D4),
              onTap: () => widget.onNavigateToTab?.call(2),
            ),
            _QuickActionCard(
              icon: Icons.receipt_long_rounded,
              label: 'My\nClaims',
              color: AppTheme.secondary,
              onTap: () => widget.onNavigateToTab?.call(3),
            ),
            _QuickActionCard(
              icon: Icons.description_rounded,
              label: 'Payslip\nDocs',
              color: AppTheme.success,
              onTap: () => _showComingSoon('Payslip Documents'),
            ),
            _QuickActionCard(
              icon: Icons.campaign_rounded,
              label: 'Announce\nments',
              color: AppTheme.warning,
              onTap: () => _showComingSoon('Announcements'),
            ),
            _QuickActionCard(
              icon: Icons.smart_toy_rounded,
              label: 'AI\nHR Help',
              color: const Color(0xFF8B5CF6),
              onTap: () => _showComingSoon('AI HR Help'),
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
                child: _MiniStat(
                  label: 'Total',
                  value: '${_viewModel.monthTotal}',
                  color: AppTheme.primary,
                ),
              ),
              Container(width: 1, height: 28, color: AppTheme.primary.withValues(alpha: 0.15)),
              Expanded(
                child: _MiniStat(
                  label: 'Present',
                  value: '${_viewModel.monthPresent}',
                  color: AppTheme.success,
                ),
              ),
              Container(width: 1, height: 28, color: AppTheme.primary.withValues(alpha: 0.15)),
              Expanded(
                child: _MiniStat(
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
              .map((r) => _RecentAttendanceRow(record: r))),
      ],
    );
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
            _ProfileRow(
                icon: Icons.badge_rounded,
                label: 'Employee ID',
                value: widget.user.employeeId),
            if (widget.user.department != null)
              _ProfileRow(
                  icon: Icons.domain_rounded,
                  label: 'Department',
                  value: widget.user.department!),
            _ProfileRow(
                icon: Icons.business_rounded,
                label: 'Company',
                value: widget.company.name),
            if (widget.user.email != null)
              _ProfileRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: widget.user.email!),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppTheme.danger),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                final nav = Navigator.of(context);
                nav.pop();
                await AuthService().signOut();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
      ],
    );
  }
}

class _ClockTimeBox extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  const _ClockTimeBox(
      {required this.label,
      required this.time,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(time,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RecentAttendanceRow extends StatelessWidget {
  final AttendanceModel record;
  const _RecentAttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isLate = record.status == 'late';
    final statusColor = isLate ? AppTheme.warning : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('EEE').format(record.date),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                Text(DateFormat('dd').format(record.date),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('d MMM yyyy').format(record.date),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(height: 3),
                Text(
                  '${record.clockIn != null ? DateFormat('hh:mm a').format(record.clockIn!) : '-'}'
                  '  →  '
                  '${record.clockOut != null ? DateFormat('hh:mm a').format(record.clockOut!) : 'Working...'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(
                  label: isLate ? 'Late' : 'Present',
                  color: statusColor),
              if (record.duration != null) ...[
                const SizedBox(height: 4),
                Text(record.durationText,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _WorkTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WorkTypeButton(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: color)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
