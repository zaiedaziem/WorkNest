import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationViewModel viewModel;

  const NotificationsScreen({super.key, required this.viewModel});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChanged);
    // Refresh when screen opens
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(
              onPressed: vm.markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: vm.load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Unread section
                      if (vm.unread.isNotEmpty) ...[
                        _sectionHeader('New', vm.unread.length),
                        ...vm.unread.map((n) => _DismissibleTile(
                              notif: n,
                              onTap: () => _onTap(n),
                              onDelete: () => _onDelete(n),
                            )),
                      ],
                      // Read section
                      if (vm.read.isNotEmpty) ...[
                        _sectionHeader('Earlier', null),
                        ...vm.read.map((n) => _DismissibleTile(
                              notif: n,
                              onTap: () => _onTap(n),
                              onDelete: () => _onDelete(n),
                            )),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('All caught up!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          const Text('No notifications yet.',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, int? count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  void _onTap(NotificationModel n) {
    widget.viewModel.markRead(n.id);
    // TODO: navigate to leave/claim screen based on n.refType
  }

  Future<void> _onDelete(NotificationModel n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Remove this notification? This cannot be undone.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.viewModel.delete(n.id);
    }
  }
}

// ── Slide-to-reveal delete tile ───────────────────────────────────────────────
class _DismissibleTile extends StatefulWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DismissibleTile({
    required this.notif,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_DismissibleTile> createState() => _DismissibleTileState();
}

class _DismissibleTileState extends State<_DismissibleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  static const double _btnWidth = 72.0;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _slide = Tween<double>(begin: 0, end: -_btnWidth)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragOffset = (_dragOffset + d.delta.dx).clamp(-_btnWidth, 0);
    _ctrl.value = (-_dragOffset / _btnWidth).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_ctrl.value > 0.4 || d.velocity.pixelsPerSecond.dx < -300) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    _dragOffset = _ctrl.value * -_btnWidth;
  }

  void _close() {
    _ctrl.reverse();
    _dragOffset = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slide,
      builder: (_, __) {
        return Stack(
          children: [
            // Red delete button revealed on the right
            Positioned(
              right: 16,
              top: 4,
              bottom: 4,
              width: _btnWidth - 8,
              child: GestureDetector(
                onTap: () {
                  _close();
                  widget.onDelete();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(height: 2),
                      Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

            // Tile slides left to reveal the button
            Transform.translate(
              offset: Offset(_slide.value, 0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                onTap: _ctrl.value > 0.1 ? _close : widget.onTap,
                child: _NotifTile(
                  notif: widget.notif,
                  onTap: _ctrl.value > 0.1 ? _close : widget.onTap,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isApproved = notif.type.contains('approved');
    final isLeave    = notif.type.contains('leave');

    final iconColor = isApproved ? AppTheme.success : AppTheme.danger;
    final iconData  = isApproved
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final typeColor = isLeave ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);
    final typeIcon  = isLeave
        ? Icons.calendar_today_rounded
        : Icons.receipt_long_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : AppTheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? const Color(0xFFF3F4F6)
                : AppTheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(iconData, size: 14, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          isApproved ? 'Approved' : 'Rejected',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: iconColor),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(notif.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime utc) {
    final local = utc.toLocal();
    final diff  = DateTime.now().difference(local);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(local);
  }
}
