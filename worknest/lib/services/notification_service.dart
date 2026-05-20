import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _db = Supabase.instance.client;
  static const _table = 'Notifications'; // EF Core PascalCase

  // ── Fetch all notifications for the current user ──────────────────────────
  Future<List<NotificationModel>> getAll(String userId) async {
    final data = await _db
        .from(_table)
        .select()
        .eq('UserId', userId)
        .order('CreatedAt', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 15));

    return (data as List).map((e) => NotificationModel.fromMap(e)).toList();
  }

  // ── Unread count ──────────────────────────────────────────────────────────
  Future<int> getUnreadCount(String userId) async {
    final data = await _db
        .from(_table)
        .select('Id')
        .eq('UserId', userId)
        .eq('IsRead', false)
        .timeout(const Duration(seconds: 15));

    return (data as List).length;
  }

  // ── Mark a single notification as read ────────────────────────────────────
  Future<void> markRead(String id) async {
    await _db
        .from(_table)
        .update({'IsRead': true})
        .eq('Id', id)
        .timeout(const Duration(seconds: 15));
  }

  // ── Mark all as read for a user ───────────────────────────────────────────
  Future<void> markAllRead(String userId) async {
    await _db
        .from(_table)
        .update({'IsRead': true})
        .eq('UserId', userId)
        .eq('IsRead', false)
        .timeout(const Duration(seconds: 15));
  }

  // ── Delete a notification ─────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _db
        .from(_table)
        .delete()
        .eq('Id', id)
        .timeout(const Duration(seconds: 15));
  }

  // ── Subscribe to new notifications via Supabase Realtime ─────────────────
  RealtimeChannel subscribe(
    String userId,
    void Function(NotificationModel) onNew,
  ) {
    return _db
        .channel('notifications_$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  _table,
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'UserId',
            value:  userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              try {
                onNew(NotificationModel.fromMap(payload.newRecord));
              } catch (_) {}
            }
          },
        )
        .subscribe();
  }
}
