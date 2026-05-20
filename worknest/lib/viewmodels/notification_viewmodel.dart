import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final String userId;
  final _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _channel;

  NotificationViewModel({required this.userId}) {
    load();
    _subscribeRealtime();
  }

  List<NotificationModel> get notifications => _notifications;
  bool   get isLoading  => _isLoading;
  String? get error     => _error;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get unread =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get read =>
      _notifications.where((n) => n.isRead).toList();

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getAll(userId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Realtime — prepend new notifications as they arrive ───────────────────
  void _subscribeRealtime() {
    _channel = _service.subscribe(userId, (newNotif) {
      _notifications = [newNotif, ..._notifications];
      notifyListeners();
    });
  }

  // ── Mark single as read ───────────────────────────────────────────────────
  Future<void> markRead(String id) async {
    // Optimistic update
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;

    _notifications = List.from(_notifications)
      ..[idx] = NotificationModel(
        id:        _notifications[idx].id,
        userId:    _notifications[idx].userId,
        companyId: _notifications[idx].companyId,
        type:      _notifications[idx].type,
        title:     _notifications[idx].title,
        body:      _notifications[idx].body,
        isRead:    true,
        refId:     _notifications[idx].refId,
        refType:   _notifications[idx].refType,
        createdAt: _notifications[idx].createdAt,
      );
    notifyListeners();

    try {
      await _service.markRead(id);
    } catch (_) {
      // Revert on failure
      await load();
    }
  }

  // ── Mark all as read ──────────────────────────────────────────────────────
  Future<void> markAllRead() async {
    if (unreadCount == 0) return;

    // Optimistic update
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id, userId: n.userId, companyId: n.companyId,
      type: n.type, title: n.title, body: n.body,
      isRead: true, refId: n.refId, refType: n.refType,
      createdAt: n.createdAt,
    )).toList();
    notifyListeners();

    try {
      await _service.markAllRead(userId);
    } catch (_) {
      await load();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
