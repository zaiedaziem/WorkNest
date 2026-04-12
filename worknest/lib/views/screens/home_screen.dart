import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../models/attendance_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;

  const HomeScreen({
    super.key,
    required this.user,
    required this.company,
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

    // Tick every second to update the clock
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _showClockInOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

            // In Office
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

            // WFH
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
    final attendance = _viewModel.todayAttendance;
    final now = _now;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${widget.user.firstName} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        widget.company.name,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      widget.user.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Clock In/Out Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha:0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      '${_dayName(now.weekday)}, ${now.day} ${_monthName(now.month)} ${now.year}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha:0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Status row
                    if (attendance != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _TimeChip(
                            label: 'Clock In',
                            time: attendance.clockIn != null
                                ? '${attendance.clockIn!.hour.toString().padLeft(2, '0')}:${attendance.clockIn!.minute.toString().padLeft(2, '0')}'
                                : '-',
                          ),
                          _TimeChip(
                            label: 'Clock Out',
                            time: attendance.clockOut != null
                                ? '${attendance.clockOut!.hour.toString().padLeft(2, '0')}:${attendance.clockOut!.minute.toString().padLeft(2, '0')}'
                                : '-',
                          ),
                          _TimeChip(
                            label: 'Duration',
                            time: attendance.durationText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Button
                    if (!_viewModel.isClockedIn)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _viewModel.isLoading
                              ? null
                              : _showClockInOptions,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Clock In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      )
                    else if (_viewModel.isClockedIn && !_viewModel.isClockedOut)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _viewModel.isLoading
                              ? null
                              : _viewModel.clockOut,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Clock Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.danger,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Attendance Complete',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Today's status
              const Text('Today\'s Status',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),

              if (_viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (attendance == null)
                _EmptyAttendance()
              else
                _AttendanceStatusCard(attendance: attendance),
            ],
          ),
        ),
      ),
    );
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _WorkTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WorkTypeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.15),
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

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;

  const _TimeChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(time,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 11)),
      ],
    );
  }
}

class _EmptyAttendance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.textMuted),
          SizedBox(width: 10),
          Text('You have not clocked in yet today.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AttendanceStatusCard extends StatelessWidget {
  final AttendanceModel attendance;

  const _AttendanceStatusCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final statusColor = attendance.status == 'present'
        ? AppTheme.success
        : attendance.status == 'late'
            ? AppTheme.warning
            : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              attendance.type == 'office'
                  ? Icons.business_rounded
                  : Icons.home_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.type == 'office' ? 'In Office' : 'Work From Home',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark),
                ),
                Text(
                  attendance.durationText != '-'
                      ? 'Duration: ${attendance.durationText}'
                      : 'Currently working...',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              attendance.status[0].toUpperCase() +
                  attendance.status.substring(1),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
